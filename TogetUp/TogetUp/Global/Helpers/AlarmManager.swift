//
//  AlarmManager.swift
//  TogetUp
//
//  Created by 이예원 on 2023/09/26.
//

import Foundation
import UserNotifications
import RealmSwift
import AudioToolbox

enum Weekday: Int, CaseIterable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    
    var alarmIdentifier: String {
        return "\(self)"
    }
}

class AlarmManager {
    static let shared = AlarmManager()
    
    private init() {}
    
    func scheduleNotification(for alarmId: Int) {
        let realm = try! Realm()
        guard let alarm = realm.objects(Alarm.self).filter("id == \(alarmId)").first else {
            print("Alarm with ID \(alarmId) not found in Realm")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "알람이 울리고 있어요!"
        content.body = "미션을 수행해주세요"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "alarmSound.mp3"))
        content.userInfo = ["alarmId": alarmId]
        
        var dateComponents = DateComponents()
        dateComponents.hour = alarm.alarmHour
        dateComponents.minute = alarm.alarmMinute
        dateComponents.second = 0
        let weekdayMap: [Weekday: Bool] = [
            .sunday: alarm.sunday,
            .monday: alarm.monday,
            .tuesday: alarm.tuesday,
            .wednesday: alarm.wednesday,
            .thursday: alarm.thursday,
            .friday: alarm.friday,
            .saturday: alarm.saturday
        ]
        
        var isAnyDaySet = false
        
        for (weekday, isSet) in weekdayMap {
            if isSet {
                dateComponents.weekday = weekday.rawValue
                isAnyDaySet = true
                let identifier = "\(alarm.id)-\(weekday.alarmIdentifier)"
                scheduleIndividualNotification(identifier: identifier, dateComponents: dateComponents, content: content)
            }
        }
        
        if !isAnyDaySet {
            scheduleIndividualNotification(identifier: "\(alarm.id)-today", dateComponents: dateComponents, content: content)
        }
    }
    
    func scheduleIndividualNotification(identifier: String, dateComponents: DateComponents, content: UNMutableNotificationContent) {
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func removeNotification(for alarmId: Int) {
        var identifiers = ["\(alarmId)-today"]
        for weekday in Weekday.allCases {
            identifiers.append("\(alarmId)-\(weekday.alarmIdentifier)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func toggleAlarmActivation(for alarmId: Int) {
        let realm = try? Realm()
        guard let alarm = realm?.objects(Alarm.self).filter("id == \(alarmId)").first else {
            print("Alarm with ID \(alarmId) not found in Realm")
            return
        }
        
        if alarm.isActivated {
            scheduleNotification(for: alarmId)
        } else {
            removeNotification(for: alarmId)
        }
    }
    
    func refreshAllScheduledNotifications() {
        guard let allAlarms = fetchAllAlarmsFromDatabase() else { return }
        for alarm in allAlarms where alarm.isActivated {
            scheduleNotification(for: alarm.id)
        }
    }
    
    func fetchAllAlarmsFromDatabase() -> [Alarm]? {
        do {
            let realm = try Realm()
            let alarms = realm.objects(Alarm.self)
            return Array(alarms)
        } catch let error {
            print("Error accessing Realm: \(error)")
            return nil
        }
    }
}
