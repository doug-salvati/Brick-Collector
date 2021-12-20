//
//  AppOperationQueueView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/20/21.
//

import SwiftUI

struct AppOperationQueueView: View {
    @EnvironmentObject private var appManager: AppManager

    var body: some View {
        let queue = appManager.queue.filter({!$0.value.dismissed})
        let arr = Array(queue.keys)
        List {
            ForEach(arr, id: \.self) { key in
                let op = queue[key];
                HStack {
                    if op?.error != nil {
                        Image(systemName: "exclamationmark.triangle")
                    } else {
                        ProgressView().scaleEffect(2/3).offset(x: 0, y: -4)
                    }
                    VStack(alignment: .leading) {
                        Text(op?.description ?? "Unknown")
                            .font(.headline)
                        Text(op?.error?.localizedDescription ?? "Loading")
                            .fontWeight(.thin)
                            .foregroundColor(Color.red)
                    }
                }
            }.onDelete { offsets in
                withAnimation {
                    offsets.map { arr[$0] }.forEach { opId in appManager.dismiss(opId: opId)}
                }
            }
        }
    }
}

struct AppOperationQueueView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        AppOperationQueueView().environmentObject(AppManager(using: manager))
    }
}
