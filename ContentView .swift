import SwiftUI
import SwiftData
import UserNotifications
import Charts

// MARK: - Main Content View
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    
    @State private var newTaskTitle = ""
    @State private var selectedCategory = Category.personal
    @State private var refreshID = UUID()
    @State private var showConfetti = false
    @State private var isShowingScanner = false
    @State private var selectedDate = Date().addingTimeInterval(3600)
    
    // Animations
    @State private var animateLava = false
    @State private var blinkOpacity = 1.0
    @State private var showSplash = true // Splash Screen State

    // Streaks & Logic
    @AppStorage("userStreak") private var userStreak = 0
    @AppStorage("streakEmoji") private var streakEmoji = "🔥"
    @AppStorage("lastCompletionDate") private var lastCompletionDate: String = ""

    // Dynamic Quotes Logic
    var dynamicQuote: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5...11: return "Good Morning! Ee roju targets ni smash chey! ☀️"
        case 12...17: return "Good Afternoon! Meeru chala active ga unnaru! ⚡️"
        case 18...21: return "Good Evening! Finish line daggara unnaru! 🌅"
        default: return "Repati kosam tasks schedule cheskundhama? 🌙"
        }
    }

    var completionProgress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter { $0.isCompleted }.count) / Double(tasks.count)
    }

    var body: some View {
        ZStack {
            if showSplash {
                // MARK: - SPLASH SCREEN UI
                splashScreenView
            } else {
                // MARK: - MAIN APP UI
                NavigationStack {
                    ZStack {
                        Color(.systemGroupedBackground).ignoresSafeArea()
                        VStack(spacing: 0) {
                            headerView
                            chartSection
                            
                            List {
                                ForEach(tasks) { task in
                                    taskRow(task)
                                        .swipeActions(edge: .leading) {
                                            Button { toggleTask(task) } label: {
                                                Label("Done", systemImage: "checkmark.circle.fill")
                                            }.tint(.green)
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button { postponeTask(task) } label: {
                                                Label("Tomorrow", systemImage: "clock.arrow.circlepath")
                                            }.tint(.orange)
                                            Button(role: .destructive) {
                                                modelContext.delete(task)
                                                triggerHaptic(.warning)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .listStyle(.insetGrouped)
                            .scrollContentBackground(.hidden)

                            inputArea
                        }
                        if showConfetti { Text("🎊 🥳 ✨").font(.system(size: 70)).zIndex(1) }
                    }
                    .navigationTitle("SmartLens")
                    .onAppear {
                        setupAnimations()
                        requestNotificationPermission()
                    }
                    .sheet(isPresented: $isShowingScanner) {
                        MockScannerView { scannedText in
                            self.newTaskTitle = scannedText
                            self.addTask()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    var splashScreenView: some View {
        ZStack {
            LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                Text("SmartLens")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Think Smart. Task Fast.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showSplash = false }
            }
        }
    }

    var headerView: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.2), lineWidth: 5)
                Circle().trim(from: 0, to: completionProgress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(completionProgress * 100))%").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
            }.frame(width: 45, height: 45)

            VStack(alignment: .leading, spacing: 2) {
                Text("SmartLens Journey").font(.subheadline.bold()).foregroundColor(.white)
                Text(dynamicQuote).font(.system(size: 9)).foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            Menu {
                Button("🔥 Fire") { streakEmoji = "🔥" }
                Button("⚡️ Bolt") { streakEmoji = "⚡️" }
            } label: {
                HStack(spacing: 4) { Text(streakEmoji); Text("\(userStreak)").bold() }
                .padding(8).background(Color.white.opacity(0.2)).cornerRadius(12).foregroundColor(.white)
            }
        }
        .padding().background {
            LinearGradient(colors: [.blue, .purple, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                .hueRotation(.degrees(animateLava ? 45 : 0))
        }.cornerRadius(18).padding([.horizontal, .top])
    }

    func taskRow(_ task: TaskItem) -> some View {
        let isLate = !task.isCompleted && task.dueDate < Date()
        let isPostponed = task.title.contains("📌")
        return HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : (isPostponed ? .orange : .blue))
                .onTapGesture { toggleTask(task) }
            VStack(alignment: .leading) {
                Text(task.title).strikethrough(task.isCompleted)
                    .foregroundColor(isLate ? .red : (isPostponed ? .orange : .primary))
                    .opacity(isLate ? blinkOpacity : 1.0)
                Text(isPostponed ? "🗓 Tomorrow's Commitment" : (isLate ? "⚠️ Overdue" : "🔔 \(task.dueDate, style: .time)"))
                    .font(.system(size: 9)).foregroundColor(isPostponed ? .orange : (isLate ? .red : .secondary))
            }
            Spacer()
            Text(task.category.rawValue).font(.system(size: 9)).padding(5).background(Color.blue.opacity(0.1)).cornerRadius(5)
        }
    }

    // MARK: - Logic & Actions

    private func setupAnimations() {
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: true)) { animateLava.toggle() }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { blinkOpacity = 0.3 }
    }

    private func triggerHaptic(_ style: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(style)
    }

    private func toggleTask(_ task: TaskItem) {
        withAnimation {
            task.isCompleted.toggle()
            if task.isCompleted {
                triggerHaptic(.success) // Professional Success Pulse
                updateStreak()
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { showConfetti = false } }
            }
            refreshID = UUID()
        }
    }

    private func postponeTask(_ task: TaskItem) {
        withAnimation {
            task.dueDate = task.dueDate.addingTimeInterval(86400)
            if !task.title.contains("📌") { task.title = "📌 " + task.title }
            triggerHaptic(.warning) // Warning Buzz for Postponing
            refreshID = UUID()
        }
    }

    private func updateStreak() {
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        if lastCompletionDate != today { userStreak += 1; lastCompletionDate = today }
    }

    private func addTask() {
        if !newTaskTitle.isEmpty {
            let item = TaskItem(title: newTaskTitle, category: selectedCategory, dueDate: selectedDate)
            modelContext.insert(item)
            triggerHaptic(.success)
            newTaskTitle = ""; selectedDate = Date().addingTimeInterval(3600); refreshID = UUID()
        }
    }

    var chartSection: some View {
        Chart {
            ForEach(Category.allCases, id: \.self) { cat in
                BarMark(x: .value("Cat", cat.rawValue), y: .value("Count", tasks.filter { $0.category == cat }.count))
                    .foregroundStyle(by: .value("Cat", cat.rawValue)).cornerRadius(4)
            }
        }.frame(height: 80).padding().id(refreshID)
    }

    var inputArea: some View {
        VStack(spacing: 8) {
            HStack {
                DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute).labelsHidden()
                Spacer()
                Picker("", selection: $selectedCategory) {
                    ForEach(Category.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.menu)
            }.padding(.horizontal)
            HStack(spacing: 12) {
                Button(action: { isShowingScanner = true }) { Image(systemName: "camera.viewfinder").font(.title2) }
                TextField("New Task...", text: $newTaskTitle).padding(10).background(Color(.systemGray6)).cornerRadius(10)
                Button(action: addTask) { Image(systemName: "plus.circle.fill").font(.system(size: 35)) }
            }.padding([.horizontal, .bottom])
        }.background(colorScheme == .dark ? Color(.tertiarySystemGroupedBackground) : Color.white)
    }

    private func requestNotificationPermission() { UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in } }
}

// MARK: - Mock Scanner View
struct MockScannerView: View {
    @State private var mockText = ""
    var onScan: (String) -> Void
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "camera.viewfinder").font(.system(size: 80)).foregroundColor(.blue).padding()
                TextField("Enter scanned text...", text: $mockText).padding().background(Color(.systemGray6)).cornerRadius(10).padding()
                Button("Complete Scan") { onScan(mockText); dismiss() }.buttonStyle(.borderedProminent)
                Spacer()
            }.toolbar { Button("Cancel") { dismiss() } }
        }
    }
}
