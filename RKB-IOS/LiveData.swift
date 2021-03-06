//
//  LiveData.swift
//
//  Created by ocean on 2016/11/9.

import Foundation
import SIOSocket
import SwiftyJSON
import VideoCore

class GameData {

    var GameIdx: Int;
    var L_name: String;
    var L_score: Int;
    var L_foul: Int;

    var R_name: String;
    var R_score: Int;
    var R_foul: Int;

    var GameState: String?
    var LeftNameFull: String
    var RightNameFull: String
      var gameTime:Int = 0;
   
    init(idx: Int,
         leftName: String, leftScore: Int, leftFoul: Int,
         rightName: String, rightScore: Int, rightFoul: Int) {
        self.GameIdx = idx;

        LeftNameFull = leftName
        RightNameFull = rightName
        var ln = leftName
        if ln.characters.count > 5 {
            ln = (ln as NSString).substring(to: 5)
        }
        self.L_name = ln
        self.L_score = leftScore;
        self.L_foul = leftFoul;

        var rn = rightName
        if rn.characters.count > 5 {
            rn = (rn as NSString).substring(to: 5)
        }
        self.R_name = rn
        self.R_score = rightScore;
        self.R_foul = rightFoul;
        
        
    }
 
    func getDrawText() -> String {
        return "第\(self.GameIdx)场 time:\(gameTime)\n蓝方:\(LeftNameFull) vs 红方:\(RightNameFull) \n得分:\(self.L_score) 犯规:\(self.L_foul)\t\t得分:\(self.R_score) 犯规:\(self.R_foul)\n";
    }


    func getInfoDrawText() -> String {
        return "idx:\(self.GameIdx) time:\(self.gameTime)\n"
    }


    func getLPDrawText() -> String {
        return "LP:\(self.L_name) \nS:\(self.L_score) F:\(self.L_foul)\n"
    }


    func getRPDrawText() -> String {
        return "             S:\(self.R_score) F:\(self.R_foul)\n RP:\(self.R_name)";
    }
}

class LiveData {
    var ws:SIOSocket?;
    var gameId: String?;
    var gameData: GameData?;
    var session: VCSimpleSession?;
    var timeCounter: Int = 0
    var isTimerRunning: Bool = false
    var isCon: Bool = false
    var srvTimer: Timer?;
//    var nowDate: Date?
    var srvTime: Double = 0

    var onMsg: ((_: String) -> Void)!

    init(wsUrl: String, gameId: String) {
        print("new LiveData\n")
        con(wsUrl: wsUrl, gameId: gameId)
    }

    func con(wsUrl: String, gameId: String) {
        self.gameId = gameId;
        if self.ws != nil{
            self.ws?.close()
        }
    
        SIOSocket.socket(withHost: wsUrl, response: {
            [weak self](socket: SIOSocket?) -> Void in
            self?.ws = socket

            socket?.onConnect = {
                () -> Void in
                print("connected\n gameId: \(gameId)")
//                self!.socket.emit("connected", args: [self!.userName])

                socket?.emit("passerbyking", args: [["game_id": gameId, "page": "score"]])

            }
            
            socket?.onDisconnect = {
                ()->Void in
                print("dis con")
            }
//
            socket?.on("wall", callback: {
                (data: Any) in
                let jd = JSON(data)[0]
                let evt = jd["et"].stringValue
                print("event", evt)
                switch evt {
                case "init":
                    self!.onInit(data: jd)
                case "updateScore":
                    self!.onUpdate(data: jd)
//                    self!.startTimer();
                case "commitGame":
                    self!.stopTimer();
//                    self!.onCommit(data: jd)
                case "timeStart":
                    self!.startTimer()
                default:
                    print(jd)
                }
            })
//
        })
    }

    func killTimer() {
        
        srvTimer?.invalidate();
        srvTimer = nil;
        count1 = 10;

    }
    func onTimeStart() -> Void {
        startTimer();
        
    }
    func onInit(data: JSON) {
        if srvTimer == nil {
            srvTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(onTick), userInfo: nil, repeats: true);
        }


        srvTime = data["t"].doubleValue / 1000

//        DispatchQueue.
        let lp = data["player"]["left"];
        let rp = data["player"]["right"];

        self.gameData = GameData(idx: data["gameIdx"].intValue,
                leftName: lp["name"].stringValue, leftScore: lp["leftScore"].intValue, leftFoul: lp["leftFoul"].intValue,
                rightName: rp["name"].stringValue, rightScore: rp["rightScore"].intValue, rightFoul: rp["rightFoul"].intValue)
//        print(self.gameData?.getDrawText() ?? "");
//        print("init",self.gameData ?? default value)

        self.render()
        self.onMsg!(self.gameData?.getDrawText() ?? "")
    }


    func timeStr(sec: Double) -> String {
        let d = Date(timeIntervalSince1970: sec)
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        return formatter.string(from: d)
    }

    func onCommit(data: JSON) {
//        self.gameData?.L_score =
    }


    func onUpdate(data: JSON) {
        let ls = data["leftScore"]
        let lf = data["leftFoul"]
        let rs = data["rightScore"]
        let rf = data["rightFoul"]

        if ls.error == nil {
            self.gameData?.L_score = ls.intValue
        }
        if lf.error == nil {
            self.gameData?.L_foul = lf.intValue
        }

        if rs.error == nil {
            self.gameData?.R_score = rs.intValue
        }

        if rf.error == nil {
            self.gameData?.R_foul = rf.intValue
        }

//        print(self.gameData?.getDrawText() ?? "");
        print("update\n")
        self.render()
        self.onMsg!(self.gameData?.getDrawText() ?? "")
    }

    @objc func onTick() {
//        timeCounter += 1
//        print("onTick:\(timeCounter)")
        srvTime += 1.0
        renderRight()
    }
    var isRenderRight: Bool = false;
    var count1: Int = 10;
    func renderRight() {

        UIGraphicsBeginImageContext(CGSize(width: 512, height: 512))
        let ctx = UIGraphicsGetCurrentContext();
        //fill bg
        ctx?.setFillColor(UIColor.black.cgColor)
        ctx?.fill(CGRect(x: 0, y: 0, width: 150, height: 70))
        //draw text
        ctx?.setTextDrawingMode(CGTextDrawingMode.fill)
//        ctx?.setFillColor(UIColor.green.cgColor)

        let fontSize = 40.0
        let font = UIFont(name: "Arial", size: CGFloat(fontSize))

        let s = timeStr(sec: srvTime)
        (s as NSString).draw(at: CGPoint(x: 0, y: 0),
                withAttributes: [NSFontAttributeName: font!,
                                 NSForegroundColorAttributeName: UIColor.green])
        imgR = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        let rect = CGRect(x: 1160, y: 910, width: 512, height: 512);
        if isRenderRight {
            self.session?.unregisterSource();
        }
        isRenderRight = true;

        count1 -= 1;
        if count1 < 0 {
            killTimer()
            return
        }
        self.session?.addPixelBufferSource(imgR, with: rect)
//        print(rect)
        imgR = nil
    }
    var imgL: UIImage?
    var imgR: UIImage?
    func render() {
        return;
        if (self.session != nil) {
            UIGraphicsBeginImageContext(CGSize(width: 512, height: 512))
            let ctx = UIGraphicsGetCurrentContext();
            //fill bg
            ctx?.setFillColor(UIColor.black.cgColor)
            ctx?.fill(CGRect(x: 0, y: 0, width: 150, height: 70))
            //draw text
            ctx?.setTextDrawingMode(CGTextDrawingMode.fill)
//            ctx?.setFillColor(UIColor.red.cgColor)
//            let text = s as NSString
            let fontSize = 20.0
            let font = UIFont(name: "Arial", size: CGFloat(fontSize))

            var s = self.gameData?.getInfoDrawText() ?? ""
//            (s as NSString).draw(at: CGPoint(x:0,y:0), withAttributes: [NSFontAttributeName:font!,NSForegroundColorAttributeName:UIColor.green])
            s = self.gameData?.getLPDrawText() ?? ""
            (s as NSString).draw(at: CGPoint(x: 0, y: 0), withAttributes: [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor.red])
            s = self.gameData?.getRPDrawText() ?? ""
            (s as NSString).draw(at: CGPoint(x: 0, y: fontSize), withAttributes: [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor.white])
            imgL = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            let rect = CGRect(x: 490, y: 910, width: 512, height: 512);
            self.session?.addPixelBufferSource(imgL, with: rect)
            imgL = nil
        }
    }
    
    
    var timer: Timer?;
  
    @objc func onGameTick() -> Void {
        self.gameData?.gameTime+=1;
           self.onMsg!(self.gameData?.getDrawText() ?? "")
    }
    func startTimer() -> Void {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(onGameTick), userInfo: nil, repeats: true);
        }
        else{
            timer?.invalidate();
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(onGameTick), userInfo: nil, repeats: true);
        }
        
    }
    func stopTimer() -> Void {
        if timer==nil{
            
        }
        else{
            self.gameData?.gameTime = 0
            timer?.invalidate();
        }
    }
}
