//
//  ProfileView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/05/2024.
//

import OSLog
import SwiftUI

struct ProfileView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofileID: ProfilesnamesRecord.ID?

    @State private var newdata = ObservableProfiles()
    @State private var uuidprofile: ProfilesnamesRecord.ID?
    @State private var localselectedprofile: String?
    @State private var newprofile: String = ""

    @State private var isPresentingConfirm: Bool = false
    @State private var allconfigurations: [SynchronizeConfiguration] = []

    var body: some View {
        VStack {
            HStack {
                Table(rsyncUIdata.validprofiles, selection: $uuidprofile) {
                    TableColumn("Profiles") { name in
                        Text(name.profilename)
                    }
                }
                .onChange(of: uuidprofile) {
                    let record = rsyncUIdata.validprofiles.filter { $0.id == uuidprofile }
                    guard record.count > 0 else {
                        localselectedprofile = nil
                        return
                    }
                    localselectedprofile = record[0].profilename
                }

                ProfilesToUpdateView(allconfigurations: allconfigurations)
            }

            EditValueScheme(300, NSLocalizedString("Create profile - press Enter when added", comment: ""),
                            $newprofile)
        }
        .onSubmit {
            createprofile()
        }
        .task {
            allconfigurations = await ReadAllTasks().readallmarkedtasks(rsyncUIdata.validprofiles)
        }
        .navigationTitle("Profile create or delete")
        .toolbar {
            ToolbarItem {
                Button {
                    isPresentingConfirm = (localselectedprofile?.isEmpty == false && localselectedprofile != nil)
                } label: {
                    Image(systemName: "trash.fill")
                        .foregroundColor(Color(.blue))
                }
                .help("Delete profile")
                .confirmationDialog("Delete \(localselectedprofile ?? "")?",
                                    isPresented: $isPresentingConfirm)
                {
                    Button("Delete", role: .destructive) {
                        deleteprofile()
                    }
                }
            }
        }
    }
}

extension ProfileView {
    func createprofile() {
        if newdata.createprofile(newprofile) {
            // Add a profile record
            rsyncUIdata.validprofiles.append(ProfilesnamesRecord(newprofile))
            if let index = rsyncUIdata.validprofiles.firstIndex(where: { $0.profilename == newprofile }) {
                // Set the profile picker and let the picker do the job
                selectedprofileID = rsyncUIdata.validprofiles[index].id
            }
            newprofile = ""
        }
    }

    func deleteprofile() {
        if let deleteprofile = localselectedprofile {
            if newdata.deleteprofile(deleteprofile) {
                selectedprofileID = nil
                // Remove the profile record
                if let index = rsyncUIdata.validprofiles.firstIndex(where: { $0.id == uuidprofile }) {
                    rsyncUIdata.validprofiles.remove(at: index)
                }
            }
        }
    }
}
