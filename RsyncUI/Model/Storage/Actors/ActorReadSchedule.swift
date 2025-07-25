//
//  ActorReadSchedule.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

actor ActorReadSchedule {
    @concurrent
    nonisolated func readjsonfilecalendar(_ validprofiles: [String]) async -> [SchedulesConfigurations]? {
        var filename = ""
        let path = await Homepath()

        Logger.process.info("ActorReadSchedule: readjsonfilecalendar() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")

        if let fullpathmacserial = path.fullpathmacserial {
            filename = fullpathmacserial.appending("/") + SharedConstants().caldenarfilejson
        }

        let decodeimport = await DecodeGeneric()
        do {
            if let data = try
                await decodeimport.decodearraydatafileURL(DecodeSchedules.self,
                                                          fromwhere: filename)
            {
                // Dont need to sort when reading, the schedules are sorted by runDate when
                // new schedules are added and saved

                Logger.process.info("ActorReadSchedule - read Calendar from permanent storage \(filename, privacy: .public)")

                return data.compactMap { element in
                    let item = SchedulesConfigurations(element)
                    if item.schedule == ScheduleType.once.rawValue,
                       let daterun = item.dateRun, daterun.en_date_from_string() < Date.now
                    {
                        return nil
                    } else {
                        if let profile = item.profile {
                            return validprofiles.contains(profile) ? item : nil
                        } else {
                            return item
                        }
                    }
                }
            }

        } catch let e {
            Logger.process.info("ActorReadSchedule: some ERROR reading")
            let error = e
            await path.propogateerror(error: error)
        }

        return nil
    }

    deinit {
        Logger.process.info("ActorReadSchedule: deinit")
    }
}

// swiftlint:enable line_length
