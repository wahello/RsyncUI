//
//  AddTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/12/2023.
//
// swiftlint:disable file_length type_body_length line_length

import SwiftUI

enum AddTaskDestinationView: String, Identifiable {
    case homecatalogs, globalchanges
    var id: String { rawValue }
}

struct AddTasks: Hashable, Identifiable {
    let id = UUID()
    var task: AddTaskDestinationView
}

enum AddConfigurationField: Hashable {
    case localcatalogField
    case remotecatalogField
    case remoteuserField
    case remoteserverField
    case synchronizeIDField
    case snapshotnumField
}

enum TypeofTask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case snapshot
    case syncremote

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct AddTaskView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var addtaskpath: [AddTasks]

    @State private var newdata = ObservableAddConfigurations()
    @State private var selectedconfig: SynchronizeConfiguration?
    // Enable change snapshotnum
    @State private var changesnapshotnum: Bool = false

    @FocusState private var focusField: AddConfigurationField?
    // Reload and show table data
    @State private var confirmcopyandpaste: Bool = false

    // URL strings
    @State private var stringverify: String = ""
    @State private var stringestimate: String = ""

    // Present a help sheet
    @State private var showhelp: Bool = false

    var body: some View {
        NavigationStack(path: $addtaskpath) {
            HStack {
                // Column 1

                VStack(alignment: .leading) {
                    HStack {
                        if newdata.selectedconfig != nil {
                            Button("Update") {
                                validateandupdate()
                            }
                            .buttonStyle(ColorfulButtonStyle())
                            .help("Update task")
                        } else {
                            Button("Add") {
                                addconfig()
                            }
                            .buttonStyle(ColorfulButtonStyle())
                            .help("Add task")
                        }

                        pickerselecttypeoftask
                            .disabled(selectedconfig != nil)

                        VStack(alignment: .leading) {
                            ToggleViewDefault(text: NSLocalizedString("Don´t add /", comment: ""),
                                              binding: $newdata.donotaddtrailingslash)
                        }
                    }
                    .padding(.bottom, 10)

                    VStack(alignment: .leading) { synchronizeID }

                    if newdata.selectedrsynccommand == .syncremote {
                        VStack(alignment: .leading) { localandremotecatalogsyncremote }

                    } else {
                        VStack(alignment: .leading) { localandremotecatalog }
                            .disabled(selectedconfig?.task == SharedReference.shared.snapshot)
                    }

                    VStack(alignment: .leading) { remoteuserandserver }
                        .disabled(selectedconfig?.task == SharedReference.shared.snapshot)

                    if selectedconfig?.task == SharedReference.shared.snapshot {
                        VStack(alignment: .leading) { snapshotnum }
                    }

                    Spacer()

                    if let selectedconfig,
                       selectedconfig.task == SharedReference.shared.synchronize
                    {
                        VStack(alignment: .leading) {
                            HStack {
                                // URLValues(300, "Select a task to save an URL for Estimate & Synchronize", $stringestimate)

                                Button {
                                    let data = WidgetURLstrings(urletimate: stringestimate, urlverify: stringverify)
                                    WriteWidgetsURLStringsJSON(data, .estimate)
                                } label: {
                                    Image(systemName: "square.and.arrow.down")
                                }
                                .disabled(stringestimate.isEmpty)
                                .help(stringestimate)
                                .buttonStyle(ColorfulButtonStyle())

                                Text("URL Estimate & Synchronize")
                            }

                            if selectedconfig.offsiteServer.isEmpty == false {
                                HStack {
                                    // URLValues(300, "Select a task to save an URL for Verify", $stringverify)

                                    Button {
                                        let data = WidgetURLstrings(urletimate: stringestimate, urlverify: stringverify)
                                        WriteWidgetsURLStringsJSON(data, .verify)
                                    } label: {
                                        Image(systemName: "square.and.arrow.down")
                                    }
                                    .disabled(stringverify.isEmpty)
                                    .help(stringverify)
                                    .buttonStyle(ColorfulButtonStyle())

                                    Text("URL Verify")
                                }
                            }
                        }
                    }
                }

                // Column 2
                VStack(alignment: .leading) {
                    if deleteparameterpresent {
                        HStack {
                            Text("Tasks for Synchronize actions.")

                            Text("If \(Text("red Synchronize ID").foregroundColor(.red)) click")

                            Button {
                                newdata.whichhelptext = 1
                                showhelp = true
                            } label: {
                                Image(systemName: "questionmark.circle")
                            }
                            .buttonStyle(HelpButtonStyle(redorwhitebutton: deleteparameterpresent))

                            Text("for more information.")
                        }
                        .padding(.bottom, 10)

                    } else {
                        HStack {
                            Text("Tasks for Synchronize actions.")

                            Text("To add --delete click")

                            Button {
                                newdata.whichhelptext = 2
                                showhelp = true
                            } label: {
                                Image(systemName: "questionmark.circle")
                            }
                            .buttonStyle(HelpButtonStyle(redorwhitebutton: deleteparameterpresent))

                            Text("for more information.")
                        }
                        .padding(.bottom, 10)
                    }

                    ListofTasksAddView(rsyncUIdata: rsyncUIdata,
                                       selecteduuids: $selecteduuids)
                        .onChange(of: selecteduuids) {
                            if let configurations = rsyncUIdata.configurations {
                                if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                    selectedconfig = configurations[index]
                                    newdata.updateview(configurations[index])
                                    // URLs
                                    if selectedconfig?.task == SharedReference.shared.synchronize {
                                        let deeplinkurl = DeeplinkURL()

                                        if selectedconfig?.offsiteServer.isEmpty == false {
                                            // Create verifyremote URL
                                            let urlverify = deeplinkurl.createURLloadandverify(valueprofile: rsyncUIdata.profile ?? "Default", valueid: selectedconfig?.backupID ?? "Synchronize ID")
                                            stringverify = urlverify?.absoluteString ?? ""
                                        }
                                        // Create estimate and synchronize URL
                                        let urlestimate = deeplinkurl.createURLestimateandsynchronize(valueprofile: rsyncUIdata.profile ?? "Default")
                                        stringestimate = urlestimate?.absoluteString ?? ""

                                    } else {
                                        stringverify = ""
                                        stringestimate = ""
                                    }

                                } else {
                                    selectedconfig = nil
                                    newdata.updateview(nil)
                                    // URL Strings
                                    stringverify = ""
                                    stringestimate = ""
                                }
                            }
                        }
                        .copyable(copyitems.filter { selecteduuids.contains($0.id) })
                        .pasteDestination(for: CopyItem.self) { items in
                            newdata.preparecopyandpastetasks(items,
                                                             rsyncUIdata.configurations ?? [])
                            guard items.count > 0 else { return }
                            confirmcopyandpaste = true
                        } validator: { items in
                            items.filter { $0.task != SharedReference.shared.snapshot }
                        }
                        .confirmationDialog(
                            Text("Copy ^[\(newdata.copyandpasteconfigurations?.count ?? 0) configuration](inflect: true)"),
                            isPresented: $confirmcopyandpaste
                        ) {
                            Button("Copy") {
                                confirmcopyandpaste = false
                                rsyncUIdata.configurations =
                                    newdata.writecopyandpastetasks(rsyncUIdata.profile,
                                                                   rsyncUIdata.configurations ?? [])
                                if SharedReference.shared.duplicatecheck {
                                    if let configurations = rsyncUIdata.configurations {
                                        VerifyDuplicates(configurations)
                                    }
                                }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showhelp) {
            switch newdata.whichhelptext {
            case 1:
                HelpView(text: newdata.helptext1)
            case 2:
                HelpView(text: newdata.helptext2)
            default:
                HelpView(text: newdata.helptext1)
            }
        }
        .onSubmit {
            switch focusField {
            case .synchronizeIDField:
                focusField = .localcatalogField
            case .localcatalogField:
                focusField = .remotecatalogField
            case .remotecatalogField:
                focusField = .remoteuserField
            case .remoteuserField:
                focusField = .remoteserverField
            case .snapshotnumField:
                validateandupdate()
            case .remoteserverField:
                if newdata.selectedconfig == nil {
                    addconfig()
                } else {
                    validateandupdate()
                }
                focusField = nil
            default:
                return
            }
        }
        .onAppear {
            if selecteduuids.count > 0 {
                // Reset preselected tasks, must do a few seconds timout
                // before clearing it out
                Task {
                    try await Task.sleep(seconds: 2)
                    selecteduuids.removeAll()
                }
            }
        }
        .onChange(of: rsyncUIdata.profile) {
            newdata.resetform()
            selecteduuids.removeAll()
            selectedconfig = nil
        }
        .toolbar {
            ToolbarItem {
                Button {
                    addtaskpath.append(AddTasks(task: .globalchanges))
                } label: {
                    Image(systemName: "globe")
                }
                .help("Global change and update")
            }

            ToolbarItem {
                Button {
                    addtaskpath.append(AddTasks(task: .homecatalogs))
                } label: {
                    Image(systemName: "house.fill")
                }
                .help("Home catalogs")
            }
        }
        .navigationTitle("Add and update tasks: profile \(rsyncUIdata.profile ?? "Default")")
        .navigationDestination(for: AddTasks.self) { which in
            makeView(view: which.task)
        }
        .padding()
    }

    @MainActor @ViewBuilder
    func makeView(view: AddTaskDestinationView) -> some View {
        switch view {
        case .homecatalogs:
            HomeCatalogsView(newdata: newdata,
                             path: $addtaskpath,
                             homecatalogs: {
                                 let fm = FileManager.default
                                 if let atpathURL = Homepath().userHomeDirectoryURLPath {
                                     var catalogs = [Catalognames]()
                                     do {
                                         for filesandfolders in try
                                             fm.contentsOfDirectory(at: atpathURL, includingPropertiesForKeys: nil)
                                             where filesandfolders.hasDirectoryPath
                                         {
                                             catalogs.append(Catalognames(filesandfolders.lastPathComponent))
                                         }
                                         return catalogs
                                     } catch {
                                         return []
                                     }
                                 }
                                 return []
                             }(),
                             attachedVolumes: {
                                 let keys: [URLResourceKey] = [.volumeNameKey,
                                                               .volumeIsRemovableKey,
                                                               .volumeIsEjectableKey]
                                 let paths = FileManager()
                                     .mountedVolumeURLs(includingResourceValuesForKeys: keys,
                                                        options: [])
                                 var volumesarray = [AttachedVolumes]()
                                 if let urls = paths {
                                     for url in urls {
                                         let components = url.pathComponents
                                         if components.count > 1, components[1] == "Volumes" {
                                             volumesarray.append(AttachedVolumes(url))
                                         }
                                     }
                                 }
                                 if volumesarray.count > 0 {
                                     return volumesarray
                                 } else {
                                     return []
                                 }
                             }())
        case .globalchanges:
            GlobalChangeTaskView(rsyncUIdata: rsyncUIdata)
        }
    }

    // Add and edit text values
    var setlocalcatalogsyncremote: some View {
        EditValueScheme(300, NSLocalizedString("Add Remote folder - required", comment: ""),
                        $newdata.localcatalog)
            .focused($focusField, equals: .localcatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setremotecatalogsyncremote: some View {
        EditValueScheme(300, NSLocalizedString("Add Source folder - required", comment: ""),
                        $newdata.remotecatalog)
            .focused($focusField, equals: .remotecatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setlocalcatalog: some View {
        EditValueScheme(300, NSLocalizedString("Add Source folder - required", comment: ""),
                        $newdata.localcatalog)
            .focused($focusField, equals: .localcatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setremotecatalog: some View {
        EditValueScheme(300, NSLocalizedString("Add Destination folder - required", comment: ""),
                        $newdata.remotecatalog)
            .focused($focusField, equals: .remotecatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    // Headers (in sections)
    var headerlocalremote: some View {
        Text("Folder parameters")
            .modifier(FixedTag(200, .leading))
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            HStack {
                // localcatalog
                if newdata.selectedconfig == nil { setlocalcatalog } else {
                    EditValueScheme(300, nil, $newdata.localcatalog)
                        .focused($focusField, equals: .localcatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear(perform: {
                            if let catalog = newdata.selectedconfig?.localCatalog {
                                newdata.localcatalog = catalog
                            }
                        })
                }
                OpencatalogView(selecteditem: $newdata.localcatalog, catalogs: true)
            }
            HStack {
                // remotecatalog
                if newdata.selectedconfig == nil { setremotecatalog } else {
                    EditValueScheme(300, nil, $newdata.remotecatalog)
                        .focused($focusField, equals: .remotecatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear(perform: {
                            if let catalog = newdata.selectedconfig?.offsiteCatalog {
                                newdata.remotecatalog = catalog
                            }
                        })
                }
                OpencatalogView(selecteditem: $newdata.remotecatalog, catalogs: true)
            }
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section(header: headerlocalremote) {
            HStack {
                // remotecatalog
                if newdata.selectedconfig == nil { setremotecatalogsyncremote } else {
                    EditValueScheme(300, nil, $newdata.remotecatalog)
                        .focused($focusField, equals: .remotecatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear(perform: {
                            if let catalog = newdata.selectedconfig?.offsiteCatalog {
                                newdata.remotecatalog = catalog
                            }
                        })
                }
                OpencatalogView(selecteditem: $newdata.remotecatalog, catalogs: true)
            }

            HStack {
                // localcatalog
                if newdata.selectedconfig == nil { setlocalcatalogsyncremote } else {
                    EditValueScheme(300, nil, $newdata.localcatalog)
                        .focused($focusField, equals: .localcatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear(perform: {
                            if let catalog = newdata.selectedconfig?.localCatalog {
                                newdata.localcatalog = catalog
                            }
                        })
                }
                OpencatalogView(selecteditem: $newdata.localcatalog, catalogs: true)
            }
        }
    }

    var setID: some View {
        EditValueScheme(300, NSLocalizedString("Add synchronize ID", comment: ""),
                        $newdata.backupID)
            .focused($focusField, equals: .synchronizeIDField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var headerID: some View {
        Text("Synchronize ID")
            .modifier(FixedTag(200, .leading))
    }

    var synchronizeID: some View {
        Section(header: headerID) {
            // Synchronize ID
            if newdata.selectedconfig == nil { setID } else {
                EditValueScheme(300, nil, $newdata.backupID)
                    .focused($focusField, equals: .synchronizeIDField)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .onAppear(perform: {
                        if let id = newdata.selectedconfig?.backupID {
                            newdata.backupID = id
                        }
                    })
            }
        }
    }

    var snapshotnumheader: some View {
        Text("Snapshotnumber")
            .modifier(FixedTag(200, .leading))
    }

    var snapshotnum: some View {
        Section(header: snapshotnumheader) {
            // Reset snapshotnum
            EditValueScheme(300, nil, $newdata.snapshotnum)
                .focused($focusField, equals: .snapshotnumField)
                .textContentType(.none)
                .submitLabel(.return)
                .disabled(!changesnapshotnum)

            ToggleViewDefault(text: NSLocalizedString("Change snapshotnumber", comment: ""),
                              binding: $changesnapshotnum)
        }
    }

    var setremoteuser: some View {
        EditValueScheme(300, NSLocalizedString("Add remote user", comment: ""),
                        $newdata.remoteuser)
            .focused($focusField, equals: .remoteuserField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setremoteserver: some View {
        EditValueScheme(300, NSLocalizedString("Add remote server", comment: ""),
                        $newdata.remoteserver)
            .focused($focusField, equals: .remoteserverField)
            .textContentType(.none)
            .submitLabel(.return)
    }

    var headerremote: some View {
        Text("Remote parameters")
            .modifier(FixedTag(200, .leading))
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            if newdata.selectedconfig == nil { setremoteuser } else {
                EditValueScheme(300, nil, $newdata.remoteuser)
                    .focused($focusField, equals: .remoteuserField)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .onAppear(perform: {
                        if let user = newdata.selectedconfig?.offsiteUsername {
                            newdata.remoteuser = user
                        }
                    })
            }
            // Remote server
            if newdata.selectedconfig == nil { setremoteserver } else {
                EditValueScheme(300, nil, $newdata.remoteserver)
                    .focused($focusField, equals: .remoteserverField)
                    .textContentType(.none)
                    .submitLabel(.return)
                    .onAppear(perform: {
                        if let server = newdata.selectedconfig?.offsiteServer {
                            newdata.remoteserver = server
                        }
                    })
            }
        }
    }

    var selectpickervalue: TypeofTask {
        switch newdata.selectedconfig?.task {
        case SharedReference.shared.synchronize:
            .synchronize
        case SharedReference.shared.syncremote:
            .syncremote
        case SharedReference.shared.snapshot:
            .snapshot
        default:
            .synchronize
        }
    }

    var pickerselecttypeoftask: some View {
        Picker(NSLocalizedString("Action", comment: "") + ":",
               selection: $newdata.selectedrsynccommand)
        {
            ForEach(TypeofTask.allCases) { Text($0.description)
                .tag($0)
            }
            .onChange(of: newdata.selectedconfig) {
                newdata.selectedrsynccommand = selectpickervalue
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 160)
    }

    var copyitems: [CopyItem] {
        if let configurations = rsyncUIdata.configurations {
            let copy = configurations.map { record in
                CopyItem(id: record.id,
                         task: record.task)
            }
            return copy
        }
        return []
    }

    var deleteparameterpresent: Bool {
        let parameter = rsyncUIdata.configurations?.filter { $0.parameter4.isEmpty == false }
        return parameter?.count ?? 0 > 0
    }
}

extension AddTaskView {
    func addconfig() {
        let profile = rsyncUIdata.profile
        rsyncUIdata.configurations = newdata.addconfig(profile, rsyncUIdata.configurations)
        if SharedReference.shared.duplicatecheck {
            if let configurations = rsyncUIdata.configurations {
                VerifyDuplicates(configurations)
            }
        }
    }

    func validateandupdate() {
        let profile = rsyncUIdata.profile
        rsyncUIdata.configurations = newdata.updateconfig(profile, rsyncUIdata.configurations)
        selecteduuids.removeAll()
    }
}

// swiftlint:enable file_length type_body_length line_length
