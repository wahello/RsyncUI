//
//  ObservableParametersRsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2021.
//

import Foundation
import Observation
import SSHCreateKey

@Observable @MainActor
final class ObservableParametersRsync {
    // Set the current value as placeholder text
    var sshport: String = ""
    // SSH keypath and identityfile, the settings View is picking up the current value
    // Set the current value as placeholder text
    var sshkeypathandidentityfile: String = ""
    // Rsync parameters
    var parameter8: String = ""
    var parameter9: String = ""
    var parameter10: String = ""
    var parameter11: String = ""
    var parameter12: String = ""
    var parameter13: String = ""
    var parameter14: String = ""
    // Selected configuration
    var configuration: SynchronizeConfiguration?
    var sshcreatekey: SSHCreateKey?
    // Add parameters
    var adddelete: Bool = false

    let helptext1 = "Red Synchronize ID means\n--delete parameter is ADDED\nTo REMOVE --delete parameter uncheck,\nAdd --delete parameter to rsync"
    let helptext2 = "To ADD --delete parameter check\nAdd --delete parameter to rsync"

    @ObservationIgnored var whichhelptext: Int = 1

    func setvalues(_ config: SynchronizeConfiguration?) {
        if let config {
            configuration = config
            parameter8 = configuration?.parameter8 ?? ""
            parameter9 = configuration?.parameter9 ?? ""
            parameter10 = configuration?.parameter10 ?? ""
            parameter11 = configuration?.parameter11 ?? ""
            parameter12 = configuration?.parameter12 ?? ""
            parameter13 = configuration?.parameter13 ?? ""
            parameter14 = configuration?.parameter14 ?? ""
            sshport = String(configuration?.sshport ?? -1)
            if sshport == "-1" { sshport = "" }
            sshkeypathandidentityfile = configuration?.sshkeypathandidentityfile ?? ""
            // --delete parameter4
            if (configuration?.parameter4 ?? "").isEmpty { adddelete = false } else { adddelete = true }

        } else {
            reset()
        }
    }

    func setbackup() {
        if let config = configuration {
            let localcatalog = config.localCatalog
            let localcatalogparts = (localcatalog as AnyObject).components(separatedBy: "/")
            if parameter12.isEmpty == false {
                parameter12 = ""
            } else {
                parameter12 = ArgumentsRsyncUserSelect().backupstrings[0]
            }
            guard localcatalogparts.count > 2 else { return }
            if config.offsiteCatalog.contains("~") {
                if parameter13.isEmpty == false {
                    parameter13 = ""
                } else {
                    parameter13 = ArgumentsRsyncUserSelect().backupstrings[1] + "_"
                        + localcatalogparts[localcatalogparts.count - 2]
                }
            } else {
                if parameter13.isEmpty == false {
                    parameter13 = ""
                } else {
                    parameter13 = ArgumentsRsyncUserSelect().backupstrings[2] + "_"
                        + localcatalogparts[localcatalogparts.count - 2]
                }
            }
            configuration?.parameter12 = parameter12
            configuration?.parameter13 = parameter13
        }
    }

    // Return the updated configuration
    func updatersyncparameters() -> SynchronizeConfiguration? {
        if var configuration {
            if parameter8.isEmpty { configuration.parameter8 = nil } else { configuration.parameter8 = parameter8 }
            if parameter9.isEmpty { configuration.parameter9 = nil } else { configuration.parameter9 = parameter9 }
            if parameter10.isEmpty { configuration.parameter10 = nil } else { configuration.parameter10 = parameter10 }
            if parameter11.isEmpty { configuration.parameter11 = nil } else { configuration.parameter11 = parameter11 }
            if parameter12.isEmpty { configuration.parameter12 = nil } else { configuration.parameter12 = parameter12 }
            if parameter13.isEmpty { configuration.parameter13 = nil } else { configuration.parameter13 = parameter13 }
            if parameter14.isEmpty { configuration.parameter14 = nil } else { configuration.parameter14 = parameter14 }
            if sshport.isEmpty {
                configuration.sshport = nil
            } else {
                configuration.sshport = Int(sshport)
            }
            if sshkeypathandidentityfile.isEmpty {
                configuration.sshkeypathandidentityfile = nil
            } else {
                configuration.sshkeypathandidentityfile = sshkeypathandidentityfile
            }
            return configuration
        }
        return nil
    }

    func reset() {
        configuration = nil
        parameter8 = ""
        parameter9 = ""
        parameter10 = ""
        parameter11 = ""
        parameter12 = ""
        parameter13 = ""
        parameter14 = ""
        sshport = ""
        sshkeypathandidentityfile = ""
        adddelete = false
    }

    func sshkeypath(_ keypath: String) -> Bool {
        guard configuration != nil else { return false }
        guard keypath.isEmpty == false else {
            configuration?.sshkeypathandidentityfile = nil
            return false
        }
        let verified = verifysshkeypath(keypath)
        if verified {
            configuration?.sshkeypathandidentityfile = keypath
            return true
        }
        return false
    }

    func setsshport(_ port: String) -> Bool {
        guard configuration != nil else { return false }
        guard port.isEmpty == false else {
            configuration?.sshport = nil
            return false
        }
        let verified = verifysshport(port)
        if verified {
            configuration?.sshport = Int(port)
            return true
        }
        return false
    }

    // Verify SSH keypathidentityfile
    func verifysshkeypath(_ keypath: String) -> Bool {
        guard keypath.isEmpty == false else { return false }
        if keypath.first != "~" { return false }
        let number = keypath.filter { $0 == "/" }.count
        guard number == 2 else { return false }
        return true
    }

    // Verify SSH port is a valid INT
    func verifysshport(_ port: String) -> Bool {
        guard port.isEmpty == false else { return false }
        if Int(port) != nil { return true }
        return false
    }

    // parameter4 --delete
    func adddelete(_ adddelete: Bool) {
        guard configuration != nil else { return }
        if adddelete {
            configuration?.parameter4 = "--delete"
        } else {
            configuration?.parameter4 = ""
        }
    }

    init() {
        sshcreatekey = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                    sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
    }
}
