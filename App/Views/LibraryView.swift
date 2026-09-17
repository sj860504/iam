import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject var library: PhoneLibraryStore
    @EnvironmentObject var connectivity: PhoneConnectivityManager
    @State private var showingImporter = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(library.items) { item in
                        row(for: item)
                    }
                    .onDelete { indexSet in
                        indexSet.map { library.items[$0] }.forEach(library.delete)
                    }
                } header: {
                    Text("내 라이브러리")
                } footer: {
                    Text("본인이 권리를 가진 오디오 파일만 추가하세요. 곡을 탭하면 워치로 전송합니다.")
                }
            }
            .navigationTitle("iam")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingImporter = true
                    } label: {
                        Label("추가", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    connectivityBadge
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: true
            ) { result in
                handleImport(result)
            }
            .alert("가져오기 실패", isPresented: .constant(importError != nil)) {
                Button("확인") { importError = nil }
            } message: {
                Text(importError ?? "")
            }
        }
    }

    private func row(for item: MediaItem) -> some View {
        Button {
            connectivity.send(item)
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.title).font(.body)
                    Text(item.artist).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "applewatch.and.arrow.forward")
                    .foregroundStyle(.tint)
            }
        }
    }

    private var connectivityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(connectivity.isReachable ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            if connectivity.pendingTransfers > 0 {
                Text("\(connectivity.pendingTransfers)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                do { try library.importFile(from: url) }
                catch { importError = error.localizedDescription }
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
}
