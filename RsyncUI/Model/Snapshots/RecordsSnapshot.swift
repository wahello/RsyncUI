//
//  RecordsSnapshot.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/08/2024.
//

import Foundation

final class RecordsSnapshot {
    var loggrecordssnapshots: [LogRecordSnapshot]?

    private func readandsortallloggdata(_ config: SynchronizeConfiguration,
                                        _ logrecords: [LogRecords])
    {
        var data: [LogRecordSnapshot]?
        let localrecords = logrecords.filter { $0.hiddenID == config.hiddenID }
        guard localrecords.count == 1 else { return }
        if let logrecords = localrecords[0].logrecords {
            data = logrecords.map { record in
                var datestring: String?
                var date: Date?
                if let stringdate = record.dateExecuted {
                    if stringdate.isEmpty == false {
                        datestring = stringdate.en_date_from_string().localized_string_from_date()
                        date = stringdate.en_date_from_string()
                    }
                }
                return LogRecordSnapshot(
                    // Pick up the id from the log record itself.
                    idlogrecord: record.id,
                    date: date ?? Date(),
                    dateExecuted: datestring ?? "",
                    resultExecuted: record.resultExecuted ?? ""
                )
            }
            loggrecordssnapshots = data?.sorted { d1, d2 in
                d1.dateExecuted.en_date_from_string() < d2.dateExecuted.en_date_from_string()
            }
        }
    }

    init(config: SynchronizeConfiguration,
         logrecords: [LogRecords])
    {
        if loggrecordssnapshots == nil {
            readandsortallloggdata(config, logrecords)
        }
    }
}
