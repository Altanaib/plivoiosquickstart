//
//  ViewController.swift
//  plivoIosQuickStart
//
//  Created by Altanai Bisht on 30/10/18.
//  Copyright © 2018 Altanai Bisht. All rights reserved.
//

import UIKit
import CallKit
import PlivoVoiceKit
import AVFoundation



class ViewController: UIViewController, CXProviderDelegate, CXCallObserverDelegate, JCDialPadDelegate, PlivoEndpointDelegate {

    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var callerNameLabel: UILabel!
    @IBOutlet weak var callStateLabel: UILabel!
    @IBOutlet weak var dialPadView: UIView!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var hideButton: UIButton!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var holdButton: UIButton!
    @IBOutlet weak var keypadButton: UIButton!
    @IBOutlet weak var speakerButton: UIButton!
    @IBOutlet weak var activeCallImageView: UIImageView!
    
    var pad: JCDialPad?
    var timer: MZTimerLabel?
    var callObserver: CXCallObserver?
    
    var isItUserAction: Bool = false
    var isItGSMCall: Bool = false
    
    var outCall: PlivoOutgoing?
    var incCall: PlivoIncoming?
    
    var isSpeakerOn: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

         Phone.sharedInstance.login(withUserName: "altanai466928765560244342301141", andPassword: "12345678")
        
    }

    func onLogin() {
        
        DispatchQueue.main.async(execute: {() -> Void in
            
            UtilClass.setUserAuthenticationStatus(true)
            //Default View Controller: ContactsViewController
            //Landing page
//            let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
//            let _appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
//            let tabbarControler: UITabBarController? = _mainStoryboard.instantiateViewController(withIdentifier: "tabBarViewController") as? UITabBarController
//            let plivoVC: PlivoCallController? = (tabbarControler?.viewControllers?[2] as? PlivoCallController)
//            Phone.sharedInstance.setDelegate(plivoVC!)
//            tabbarControler?.selectedViewController = tabbarControler?.viewControllers?[1]
//            _appDelegate?.window?.rootViewController = tabbarControler
//            let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
//            appDelegate?.voipRegistration()

//            UtilClass.hideToastActivity()
//            UtilClass.makeToast(kLOGINSUCCESS)

            let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
            appDelegate?.voipRegistration()
            print("Ready to make a call");
            
            self.pad = JCDialPad(frame: self.dialPadView.bounds)
            self.pad?.buttons = JCDialPad.defaultButtons()
            self.pad?.delegate = self
            self.pad?.showDeleteButton = true
            self.pad?.formatTextToPhoneNumber = false
            self.dialPadView.backgroundColor = UIColor.white
            self.dialPadView.addSubview(self.pad!)
            self.timer = MZTimerLabel(label: self.callStateLabel, andTimerType: MZTimerLabelTypeStopWatch)
            self.timer?.timeFormat = "HH:mm:ss"
            CallKitInstance.sharedInstance.callKitProvider?.setDelegate(self, queue: DispatchQueue.main)
            CallKitInstance.sharedInstance.callObserver?.setDelegate(self, queue: DispatchQueue.main)
            
            //Add Call Interruption observers
            //self.addObservers()
            
        })
    }
    
    /**
     * onLoginFailed delegate implementation.
     */
    func onLoginFailed() {
        DispatchQueue.main.async(execute: {() -> Void in

            UtilClass.setUserAuthenticationStatus(false)
            
//            UtilClass.hideToastActivity()
//            UtilClass.makeToast(kLOGINFAILMSG)

            print("%@",kLOGINFAILMSG);
            self.view.isUserInteractionEnabled = true
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        Phone.sharedInstance.setDelegate(self)
        hideActiveCallView()
        pad?.buttons = JCDialPad.defaultButtons()
        pad?.layoutSubviews()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        UserDefaults.standard.set(false, forKey: "Keypad Enabled")
        UserDefaults.standard.synchronize()
        pad?.layoutSubviews()
        pad?.digitsTextField.text = ""
        pad?.showDeleteButton = false
        pad?.rawText = ""
        muteButton.isEnabled = false
        holdButton.isEnabled = false
        keypadButton.isEnabled = false
        hideActiveCallView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
//    func addObservers() {
//        // add interruption handler
//        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handleInterruption), name: NSNotification.Name.AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
//        // we don't do anything special in the route change notification
//        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handleRouteChange), name: NSNotification.Name.AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance())
//        // if media services are reset, we need to rebuild our audio chain
//        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handleMediaServerReset), name: NSNotification.Name.AVAudioSession.mediaServicesWereResetNotification, object: AVAudioSession.sharedInstance())
//        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appWillTerminate), name: NSNotification.Name.UIApplication.willTerminateNotification, object: nil)
//
//    }
    
    
    
    
    /**
     * onIncomingCall delegate implementation
     */
    
    func onIncomingCall(_ incoming: PlivoIncoming) {
        
        switch AVAudioSession.sharedInstance().recordPermission
        {
        case AVAudioSession.RecordPermission.granted:
            
            print("Permission granted")
            
            DispatchQueue.main.async(execute: {() -> Void in
                self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers?[2]
                self.userNameTextField.text = ""
                self.pad?.digitsTextField.text = ""
                self.pad?.rawText = ""
                self.callerNameLabel.text = incoming.fromUser
                self.callStateLabel.text = "Incoming call..."
            })
            CallKitInstance.sharedInstance.callKitProvider?.setDelegate(self, queue: DispatchQueue.main)
            CallKitInstance.sharedInstance.callObserver?.setDelegate(self, queue: DispatchQueue.main)
            CallInfo.addCallsInfo(callInfo:[incoming.fromUser,Date()])
            
            //Added by Siva on Tue 11th, 2017
            if !(incCall != nil) && !(outCall != nil) {
                /* log it */
                print("Incoming Call from %@", incoming.fromContact);
                /* assign incCall var */
                incCall = incoming
                outCall = nil
                CallKitInstance.sharedInstance.callUUID = UUID()
                reportIncomingCall(from: incoming.fromUser, with: CallKitInstance.sharedInstance.callUUID!)
            }
            else {
                /*
                 * Reject the call when we already have active ongoing call
                 */
                incoming.reject()
                return
            }
            break
            
        case AVAudioSession.RecordPermission.denied:
            print("Pemission denied")
            print("Please go to settings and turn on Microphone service for incoming/outgoing calls.")
            incoming.reject()
            break
            
        case AVAudioSession.RecordPermission.undetermined:
            print("Request permission here")
            break
            
        default:
            break
        }
        
    }
    
    /**
     * onIncomingCallHangup delegate implementation.
     */
    
    func onIncomingCallHangup(_ incoming: PlivoIncoming) {
        print("- Incoming call ended");
        if (incCall != nil) {
            self.isItUserAction = true
            performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
            incCall = nil
        }
    }
    
    /**
     * onIncomingCallRejected implementation.
     */
    func onIncomingCallRejected(_ incoming: PlivoIncoming) {
        /* log it */
        self.isItUserAction = true
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
        incCall = nil
    }
    
    /**
     * onOutgoingCallAnswered delegate implementation
     */
    func onOutgoingCallAnswered(_ call: PlivoOutgoing) {
        
        print("Call id in Answerd is:")
        print(call.callId)
        
        print("- On outgoing call answered");
        DispatchQueue.main.async(execute: {() -> Void in
            self.muteButton.isEnabled = true
            self.keypadButton.isEnabled = true
            self.holdButton.isEnabled = true
            self.pad?.digitsTextField.isHidden = true
            if !(self.timer != nil) {
                self.timer = MZTimerLabel(label: self.callStateLabel, andTimerType: MZTimerLabelTypeStopWatch)
                self.timer?.timeFormat = "HH:mm:ss"
                self.timer?.start()
            }
            else {
                self.timer?.start()
            }
        })
    }
    
    /**
     * onOutgoingCallHangup delegate implementation.
     */
    
    func onOutgoingCallHangup(_ call: PlivoOutgoing) {
        
        print("Call id in Hangup is:")
        print(call.callId)
        
        self.isItUserAction = true
        
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
    }
    
    func onCalling(_ call: PlivoOutgoing) {
        
        print("Call id in onCalling is:")
        print(call.callId)
        
        print("On Caling");
    }
    
    /**
     * onOutgoingCallRinging delegate implementation.
     */
    func onOutgoingCallRinging(_ call: PlivoOutgoing) {
        
        print("Call id in Ringing is:")
        print(call.callId)
        
        DispatchQueue.main.async(execute: {() -> Void in
            self.callStateLabel.text = "Ringing..."
        })
    }
    
    /**
     * onOutgoingCallrejected delegate implementation.
     */
    func onOutgoingCallRejected(_ call: PlivoOutgoing) {
        
        print("Call id in Rejected is:")
        print(call.callId)
        
        self.isItUserAction = true
        
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
    }
    
    /**
     * onOutgoingCallInvalid delegate implementation.
     */
    func onOutgoingCallInvalid(_ call: PlivoOutgoing) {
        
        print("Call id in Invalid is:")
        print(call.callId)
        
        self.isItUserAction = true
        
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
    }
    
    
    // MARK: - CallKit Actions
    func performStartCallAction(with uuid: UUID, handle: String) {
        

        switch AVAudioSession.sharedInstance().recordPermission {
                
        case AVAudioSession.RecordPermission.granted:
                print("Permission granted");
                hideActiveCallView()
                unhideActiveCallView()
                print("Outgoing call uuid is: %@", uuid);
                CallKitInstance.sharedInstance.callKitProvider?.setDelegate(self, queue: DispatchQueue.main)
                CallKitInstance.sharedInstance.callObserver?.setDelegate(self, queue: DispatchQueue.main)
                print("provider:performStartCallActionWithUUID:");
                if uuid == nil || handle == nil {
                    print("UUID or Handle nil");
                    return
                }
                
                CallInfo.addCallsInfo(callInfo:[handle,Date()])
                
                var newHandleString: String = handle.replacingOccurrences(of: "-", with: "")
                if (newHandleString as NSString).range(of: "+91").location == NSNotFound && (newHandleString.characters.count) == 10 {
                    newHandleString = "+91\(newHandleString)"
                }
                let callHandle = CXHandle(type: .generic, value: newHandleString)
                let startCallAction = CXStartCallAction(call: uuid, handle: callHandle)
                let transaction = CXTransaction(action:startCallAction)
                CallKitInstance.sharedInstance.callKitCallController?.request(transaction, completion: {(_ error: Error?) -> Void in
                    if error != nil {
                        print("StartCallAction transaction request failed: %@", error.debugDescription);
//                        DispatchQueue.main.async(execute: {() -> Void in
//                            UtilClass.makeToast(kSTARTACTIONFAILED)
//                        })
                    }
                    else {
                        print("StartCallAction transaction request successful");
                        let callUpdate = CXCallUpdate()
                        callUpdate.remoteHandle = callHandle
                        callUpdate.supportsDTMF = true
                        callUpdate.supportsHolding = true
                        callUpdate.supportsGrouping = false
                        callUpdate.supportsUngrouping = false
                        callUpdate.hasVideo = false
                        DispatchQueue.main.async(execute: {() -> Void in
                            self.callerNameLabel.text = handle
                            self.callStateLabel.text = "Calling..."
                            self.unhideActiveCallView()
                            CallKitInstance.sharedInstance.callKitProvider?.reportCall(with: uuid, updated: callUpdate)
                        })
                    }
                })
                break
        case AVAudioSession.RecordPermission.denied:
                print("Please go to settings and turn on Microphone service for incoming/outgoing calls.");
                break
        case AVAudioSession.RecordPermission.undetermined:
                // This is the initial state before a user has made any choice
                // You can use this spot to request permission here if you want
                break
            default:
                break
            }
        
    }
    
    func reportIncomingCall(from: String, with uuid: UUID) {
        
        let callHandle = CXHandle(type: .generic, value: from)
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = callHandle
        callUpdate.supportsDTMF = true
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = false
        
        CallKitInstance.sharedInstance.callKitProvider?.reportNewIncomingCall(with: uuid, update: callUpdate, completion: {(_ error: Error?) -> Void in
            if error != nil {
                print("Failed to report incoming call successfully: %@", error.debugDescription);
                //[UtilityClass makeToast:kREQUESTFAILED];
                Phone.sharedInstance.stopAudioDevice()
                if (self.incCall != nil) {
                    if self.incCall?.state != Ongoing {
                        print("Incoming call - Reject");
                        self.incCall?.reject()
                    }
                    else {
                        print("Incoming call - Hangup");
                        self.incCall?.hangup()
                    }
                    self.incCall = nil
                }
            }
            else {
                print("Incoming call successfully reported.");
                Phone.sharedInstance.configureAudioSession()
            }
        })
    }
    
    func performEndCallAction(with uuid: UUID) {
        
        DispatchQueue.main.async(execute: {() -> Void in
            
            print("performEndCallActionWithUUID: %@",uuid);
            
            let endCallAction = CXEndCallAction(call: uuid)
            let trasanction = CXTransaction(action:endCallAction)
            CallKitInstance.sharedInstance.callKitCallController?.request(trasanction, completion: {(_ error: Error?) -> Void in
                if error != nil {
                    print("EndCallAction transaction request failed: %@", error.debugDescription);
                    
                    DispatchQueue.main.async(execute: {() -> Void in
                        
                        Phone.sharedInstance.stopAudioDevice()
                        
                        if (self.incCall != nil) {
                            if self.incCall?.state != Ongoing {
                                print("Incoming call - Reject");
                                self.incCall?.reject()
                            }
                            else {
                                print("Incoming call - Hangup");
                                self.incCall?.hangup()
                            }
                            self.incCall = nil
                        }
                        
                        if (self.outCall != nil) {
                            print("Outgoing call - Hangup");
                            self.outCall?.hangup()
                            self.outCall = nil
                        }
                        
                        self.hideActiveCallView()
                        
                        self.tabBarController?.tabBar.isHidden = false
                        self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers?[1]
                    })
                }
                else {
                    
                    print("EndCallAction transaction request successful");
                }
            })
        })
    }
    
    
    // MARK: - CXCallObserverDelegate
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call == nil || call.hasEnded == true {
            print("CXCallState : Disconnected");
        }
        if call.isOutgoing == true && call.hasConnected == false {
            print("CXCallState : Dialing");
        }
        if call.isOutgoing == false && call.hasConnected == false && call.hasEnded == false && call != nil {
            print("CXCallState : Incoming");
        }
        if call.hasConnected == true && call.hasEnded == false {
            print("CXCallState : Connected");
        }
    }
    
    
    // MARK: - CXProvider Handling
    
    func providerDidReset(_ provider: CXProvider) {
        print("ProviderDidReset");
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        print("providerDidBegin");
    }
    
    private func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("provider:didActivateAudioSession");
        Phone.sharedInstance.startAudioDevice()
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("provider:didDeactivateAudioSession:");
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("provider:timedOutPerformingAction:");
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("provider:performStartCallAction:");
        Phone.sharedInstance.configureAudioSession()
        //Set extra headers
        let extraHeaders: [AnyHashable: Any] = [
            "X-PH-Header1" : "Value1",
            "X-PH-Header2" : "Value2"
        ]
        
        let dest: String = action.handle.value
        //Make the call
        outCall = Phone.sharedInstance.call(withDest: dest, andHeaders: extraHeaders)
        if (outCall != nil) {
            action.fulfill(withDateStarted: Date())
        }
        else {
            action.fail()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        if action.isOnHold {
            Phone.sharedInstance.stopAudioDevice()
        }
        else {
            Phone.sharedInstance.startAudioDevice()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        if action.isMuted {
            muteButton.setImage(UIImage(named: "Unmute.png"), for: .normal)
            if (incCall != nil) {
                incCall?.unmute()
            }
            if (outCall != nil) {
                outCall?.unmute()
            }
        }
        else {
            muteButton.setImage(UIImage(named: "MuteIcon.png"), for: .normal)
            if (incCall != nil) {
                incCall?.mute()
            }
            if (outCall != nil) {
                outCall?.mute()
            }
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("provider:performAnswerCallAction:");
        //Answer the call
        if (incCall != nil) {
            CallKitInstance.sharedInstance.callUUID = action.callUUID
            incCall?.answer()
        }
        outCall = nil
        action.fulfill()
        DispatchQueue.main.async(execute: {() -> Void in
            self.unhideActiveCallView()
            self.muteButton.isEnabled = true
            self.holdButton.isEnabled = true
            self.keypadButton.isEnabled = true
            if !(self.timer != nil) {
                self.timer = MZTimerLabel(label: self.callStateLabel, andTimerType: MZTimerLabelTypeStopWatch)
                self.timer?.timeFormat = "HH:mm:ss"
                self.timer?.start()
            }
            else {
                self.timer?.start()
            }
        })
    }
    
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        print("provider:performPlayDTMFCallAction:");
        let dtmfDigits: String = action.digits
        if (incCall != nil) {
            incCall?.sendDigits(dtmfDigits)
        }
        if (outCall != nil) {
            outCall?.sendDigits(dtmfDigits)
        }
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        
        DispatchQueue.main.async(execute: {() -> Void in
            
            if !self.isItGSMCall || self.isItUserAction {
                
                print("provider:performEndCallAction:");
                
                Phone.sharedInstance.stopAudioDevice()
                if (self.incCall != nil) {
                    if self.incCall?.state != Ongoing {
                        print("Incoming call - Reject");
                        self.incCall?.reject()
                    }
                    else {
                        print("Incoming call - Hangup");
                        self.incCall?.hangup()
                    }
                    self.incCall = nil
                }
                if (self.outCall != nil) {
                    print("Outgoing call - Hangup");
                    self.outCall?.hangup()
                    self.outCall = nil
                }
                action.fulfill()
                self.isItUserAction = false
                self.tabBarController?.tabBar.isHidden = false
                self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers?[1]
            }
            else {
                print("GSM - provider:performEndCallAction:");
            }
        })
    }
    
    // MARK: - Handling IBActions
    @IBAction func callButtonTapped(_ sender: Any) {
        
        if UtilClass.isNetworkAvailable(){
            
            switch AVAudioSession.sharedInstance().recordPermission {
                
            case AVAudioSession.RecordPermission.granted:
                
                if (!(userNameTextField.text! == "SIP URI or Phone Number") && !UtilClass.isEmpty(userNameTextField.text!)) || !UtilClass.isEmpty(pad!.digitsTextField.text!) || (incCall != nil) || (outCall != nil) {
                    
                    let img: UIImage? = (sender as AnyObject).image(for: .normal)
                    let data1: NSData? = img!.pngData() as NSData?
                    
                    if (data1?.isEqual(UIImage(named: "MakeCall.png")!.pngData()))! {
                        
                        callStateLabel.text = "Calling..."
                        callerNameLabel.text = pad?.digitsTextField.text
                        unhideActiveCallView()
                        var handle: String
                        if !(pad?.digitsTextField.text == "") {
                            handle = (pad?.digitsTextField.text!)!
                        }
                        else if !(userNameTextField.text == "") {
                            handle = userNameTextField.text!
                        }
                        else {
                            //UtilClass.makeToast(kINVALIDSIPENDPOINTMSG)
                            return
                        }
                        
                        userNameTextField.text = ""
                        pad?.digitsTextField.text = ""
                        pad?.rawText = ""
                        CallKitInstance.sharedInstance.callUUID = UUID()
                        /* outgoing call */
                        performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: handle)
                        
                    }
                    else if (data1?.isEqual(UIImage(named: "EndCall.png")!.pngData()))! {
                        
                        isItUserAction = true
                        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
                    }
                }
                else {
                    print(kINVALIDSIPENDPOINTMSG);
                }
                break
            case AVAudioSession.RecordPermission.denied:
                print("Please go to settings and turn on Microphone service for incoming/outgoing calls.")
                break
            case AVAudioSession.RecordPermission.undetermined:
                // This is the initial state before a user has made any choice
                // You can use this spot to request permission here if you want
                break
            default:
                break
            }
        }else{
            print("Please connect to internet")
        }
        
    }
    
    /*
     * Display Dial pad to enter DTMF text
     * Hide Mute/Unmute button
     * Hide Hold/Unhold button
     */
    @IBAction func keypadButtonTapped(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "Keypad Enabled")
        UserDefaults.standard.synchronize()
        holdButton.isHidden = true
        muteButton.isHidden = true
        keypadButton.isHidden = true
        hideButton.isHidden = false
        speakerButton.isHidden = true
        activeCallImageView.isHidden = true
        userNameTextField.text = ""
        view.bringSubviewToFront(hideButton)
        userNameTextField.isHidden = false
        userNameTextField.textColor = UIColor.white
        dialPadView.isHidden = false
        dialPadView.backgroundColor = UIColor(red: CGFloat(0.0 / 255.0), green: CGFloat(75.0 / 255.0), blue: CGFloat(58.0 / 255.0), alpha: CGFloat(1.0))
        dialPadView.alpha = 0.7
        pad?.buttons = JCDialPad.defaultButtons()
        pad?.layoutSubviews()
        callerNameLabel.isHidden = true
        callStateLabel.isHidden = true
    }
    
    /*
     * Hide Dial pad view
     * UnHide Mute/Unmute button
     * UnHide Hold/Unhold button
     */
    
    @IBAction func hideButtonTapped(_ sender: Any) {
        UserDefaults.standard.set(false, forKey: "Keypad Enabled")
        UserDefaults.standard.synchronize()
        holdButton.isHidden = false
        muteButton.isHidden = false
        speakerButton.isHidden = false
        keypadButton.isHidden = false
        dialPadView.isHidden = true
        hideButton.isHidden = true
        activeCallImageView.isHidden = false
        userNameTextField.isHidden = true
        userNameTextField.textColor = UIColor.darkGray
        pad?.rawText = ""
        callerNameLabel.isHidden = false
        callStateLabel.isHidden = false
        dialPadView.backgroundColor = UIColor.white
        pad?.buttons = JCDialPad.defaultButtons()
        pad?.layoutSubviews()
    }
    
    /*
     * Mute/Unmute calls
     */
    @IBAction func muteButtonTapped(_ sender: Any) {
        let img: UIImage? = (sender as AnyObject).image(for: .normal)
        
        let data1: NSData? = img!.pngData() as NSData?
        
        if (data1?.isEqual(UIImage(named: "Unmute.png")!.pngData()))! {
            
            DispatchQueue.main.async(execute: {() -> Void in
                self.muteButton.setImage(UIImage(named: "MuteIcon.png"), for: .normal)
            })
            if (incCall != nil) {
                incCall?.mute()
            }
            if (outCall != nil) {
                outCall?.mute()
            }
        }
        else {
            
            DispatchQueue.main.async(execute: {() -> Void in
                self.muteButton.setImage(UIImage(named: "Unmute.png"), for: .normal)
            })
            if (incCall != nil) {
                incCall?.unmute()
            }
            if (outCall != nil) {
                outCall?.unmute()
            }
        }
    }
    
    /*
     * Hold/Unhold calls
     */
    @IBAction func holdButtonTapped(_ sender: Any) {
        
        let img: UIImage? = (sender as AnyObject).image(for: .normal)
        
        let data1: NSData? = img!.pngData() as NSData?
        
        if (data1?.isEqual(UIImage(named: "UnholdIcon.png")!.pngData()))! {
            
            DispatchQueue.main.async(execute: {() -> Void in
                self.holdButton.setImage(UIImage(named: "HoldIcon.png"), for: .normal)
            })
            if (incCall != nil) {
                incCall?.hold()
            }
            if (outCall != nil) {
                outCall?.hold()
            }
            Phone.sharedInstance.stopAudioDevice()
            
        }
        else {
            
            DispatchQueue.main.async(execute: {() -> Void in
                self.holdButton.setImage(UIImage(named: "UnholdIcon.png"), for: .normal)
            })
            if (incCall != nil) {
                incCall?.unhold()
            }
            if (outCall != nil) {
                outCall?.unhold()
            }
            Phone.sharedInstance.startAudioDevice()
            
        }
    }
    
    
    @IBAction func speakerButtonTapped(_ sender: Any) {
        
        handleSpeaker()
        
    }
    
    
    func handleSpeaker() {
        
        let audioSession = AVAudioSession.sharedInstance()
        
        if(isSpeakerOn)
        {
            self.speakerButton.setImage(UIImage(named: "Speaker.png"), for: .normal)
            
            do {
                try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            } catch let error as NSError {
                print("audioSession error: \(error.localizedDescription)")
            }
            isSpeakerOn = false
        }
        else
        {
            self.speakerButton.setImage(UIImage(named: "Speaker_Selected.png"), for: .normal)
            
            /* Enable Speaker Phone mode */
            
            do {
                try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            } catch let error as NSError {
                print("audioSession error: \(error.localizedDescription)")
            }
            
            isSpeakerOn = true
            
        }
    }
    
    func hideActiveCallView() {
        UIDevice.current.isProximityMonitoringEnabled = false
        callerNameLabel.isHidden = true
        callStateLabel.isHidden = true
        activeCallImageView.isHidden = true
        muteButton.isHidden = true
        keypadButton.isHidden = true
        holdButton.isHidden = true
        dialPadView.isHidden = false
        userNameTextField.isHidden = false
        userNameTextField.isEnabled = true
        pad?.digitsTextField.isHidden = false
        pad?.showDeleteButton = true
        pad?.rawText = ""
        userNameTextField.text = "SIP URI or Phone Number"
        tabBarController?.tabBar.isHidden = false
        callButton.setImage(UIImage(named: "MakeCall.png"), for: .normal)
        timer?.reset()
        timer?.removeFromSuperview()
        timer = nil
        callStateLabel.text = "Calling..."
        dialPadView.alpha = 1.0
        dialPadView.backgroundColor = UIColor.white
        
        //handleSpeaker()
        resetCallButtons()
    }
    
    func resetCallButtons() {
        self.speakerButton.setImage(UIImage(named: "Speaker.png"), for: .normal)
        isSpeakerOn = false
        muteButton.setImage(UIImage(named: "Unmute.png"), for: .normal)
        self.holdButton.setImage(UIImage(named: "UnholdIcon.png"), for: .normal)
        
    }
    
    func unhideActiveCallView() {
        UIDevice.current.isProximityMonitoringEnabled = true
        callerNameLabel.isHidden = false
        callStateLabel.isHidden = false
        activeCallImageView.isHidden = false
        muteButton.isHidden = false
        keypadButton.isHidden = false
        holdButton.isHidden = false
        dialPadView.isHidden = true
        userNameTextField.isHidden = true
        pad?.digitsTextField.isHidden = true
        pad?.showDeleteButton = false
        tabBarController?.tabBar.isHidden = true
        callButton.setImage(UIImage(named: "EndCall.png"), for: .normal)
    }
    
    
    /*
     * Handle audio interruptions
     * AVAudioSessionInterruptionTypeBegan
     * AVAudioSessionInterruptionTypeEnded
     */
    
    @objc func handleInterruption(_ notification: Notification)
    {
        
        if self.incCall != nil || self.outCall != nil
        {
            guard let userInfo = notification.userInfo,
                let interruptionTypeRawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeRawValue) else {
                    return
            }
            
            switch interruptionType {
                
            case .began:
                
                self.isItGSMCall = true
                Phone.sharedInstance.stopAudioDevice()
                print("----------AVAudioSessionInterruptionTypeBegan-------------")
                break
                
            case .ended:
                
                self.isItGSMCall = false
                
                // make sure to activate the session
                let error: Error? = nil
                try? AVAudioSession.sharedInstance().setActive(true)
                if nil != error {
                    print("AVAudioSession set active failed with error")
                    Phone.sharedInstance.startAudioDevice()
                }
                print("----------AVAudioSessionInterruptionTypeEnded-------------")
                break
            }
            
        }
    }
    
    @objc func handleRouteChange(_ notification: Notification)
    {
        
    }
    
    @objc func handleMediaServerReset(_ notification: Notification) {
        print("Media server has reset");
        // rebuild the audio chain
        Phone.sharedInstance.configureAudioSession()
        Phone.sharedInstance.startAudioDevice()
    }
    
    /*
     * Will be called when app terminates
     * End on going calls(If any)
     */
    
    func appWillTerminate() {
        performEndCallAction(with: CallKitInstance.sharedInstance.callUUID!)
    }
    
    
    // MARK: - JCDialPadDelegates
    func dialPad(_ dialPad: JCDialPad, shouldInsertText text: String, forButtonPress button: JCPadButton) -> Bool {
        if !(incCall != nil) && !(outCall != nil) {
            userNameTextField.isEnabled = false
            userNameTextField.text = ""
        }
        return true
    }
    
    func dialPad(_ dialPad: JCDialPad, shouldInsertText text: String, forLongButtonPress button: JCPadButton) -> Bool {
        if !(incCall != nil) && !(outCall != nil) {
            userNameTextField.text = ""
            userNameTextField.isEnabled = false
        }
        return true
    }
    
    func getDtmfText(_ dtmfText: String, withAppendStirng appendText: String) {
        if (incCall != nil) {
            incCall?.sendDigits(dtmfText)
            userNameTextField.text = appendText
        }
        if (outCall != nil) {
            outCall?.sendDigits(dtmfText)
            userNameTextField.text = appendText
        }
    }
    
    // MARK: - Handling TextField
    /**
     * Hide keyboard after user press 'return' key
     */
    func textFieldShouldReturn(_ theTextField: UITextField) -> Bool {
        if theTextField == userNameTextField {
            theTextField.resignFirstResponder()
        }
        return true
    }
    
    /**
     * Hide keyboard when text filed being clicked
     */
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // return NO to disallow editing.
        userNameTextField.text = ""
        return true
    }
    
    /**
     *  Hide keyboard when user touches on UI
     *
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            // ...
            if touch.phase == .began
            {
                userNameTextField.resignFirstResponder()
                
            }
        }
        super.touchesBegan(touches, with: event)
    }

}

