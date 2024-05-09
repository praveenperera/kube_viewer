//
//  ContainerStatePopoverView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-09-01.
//

import SwiftUI

struct ContainerStatePopoverView: View {
    let name: String
    let state: ContainerState

    var body: some View {
        switch state {
        case let .running(data: running):
            renderRunning(running)
        case let .terminated(data: terminated):
            renderTerminated(terminated)
        case let .waiting(data: waiting):
            renderWaiting(waiting)
        }
    }

    func renderRunning(_ data: ContainerStateRunning) -> some View {
        VStack {
            Text("Running").padding(.bottom, 6).bold()

            HStack {
                Text("Name: ").bold()
                Text(name)
                Spacer()
            }.padding(.bottom, 2)

            HStack {
                Text("Started At: ").bold()
                Text(unixToUtcString(unix: data.startedAt) ?? "")
                Spacer()
            }
        }
    }

    func renderTerminated(_ data: ContainerStateTerminated) -> some View {
        VStack {
            Text("Terminated").padding(.bottom, 6).bold()

            HStack {
                Text("Name: ").bold()
                Text(name)
                Spacer()
            }.padding(.bottom, 2)

            HStack {
                Text("Started At: ").bold()
                Text(unixToUtcString(unix: data.startedAt) ?? "")
                Spacer()
            }.padding(.bottom, 2)

            HStack {
                Text("Exit Code: ").bold()
                Text(String(data.exitCode))
                Spacer()
            }.padding(.bottom, 2)

            if let reason = data.reason {
                HStack {
                    Text("Reason: ").bold()
                    Text(reason)
                    Spacer()
                }.padding(.bottom, 2)
            }
            if let message = data.message {
                HStack {
                    Text("Message: ").bold()
                    Text(message)
                    Spacer()
                }.padding(.bottom, 2)
            }
            if let signal = data.signal {
                HStack {
                    Text("signal: ").bold()
                    Text(String(signal))
                    Spacer()
                }.padding(.bottom, 2)
            }
        }
    }

    func renderWaiting(_ data: ContainerStateWaiting) -> some View {
        VStack {
            Text("Waiting").padding(.bottom, 6).bold()

            HStack {
                Text("Name: ").bold()
                Text(name)
                Spacer()
            }.padding(.bottom, 2)

            if let reason = data.reason {
                HStack {
                    Text("Reason: ").bold()
                    Text(reason)
                    Spacer()
                }.padding(.bottom, 2)
            }
            if let message = data.message {
                HStack {
                    Text("Message: ").bold()
                    Text(message)
                    Spacer()
                }.padding(.bottom, 2)
            }
        }
    }
}

struct ContainerStatePopoverView_Previews: PreviewProvider {
    static var previews: some View {
        ContainerStatePopoverView(name: "long-container-name", state: podContainerStateRunning())
            .previewDisplayName("Running")
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        ContainerStatePopoverView(name: "long-container-name", state: podContainerStateTerminated())
            .previewDisplayName("Terminated")
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        ContainerStatePopoverView(name: "long-container-name", state: podContainerStateWaiting())
            .previewDisplayName("Waiting")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
