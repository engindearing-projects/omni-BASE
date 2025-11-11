import SwiftUI

// MARK: - ATAK Tools Menu View
// Comprehensive tools menu with 5x4 grid layout matching ATAK interface

struct ATAKToolsView: View {
    @Binding var isPresented: Bool
    @State private var showAlertDialog = false
    @State private var showBrightnessControl = false
    @State private var selectedTool: ATAKTool?

    let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 5)

    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                ToolsHeader(onClose: { isPresented = false })

                // Tools Grid (5x4 layout)
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(ATAKTool.allTools) { tool in
                            ToolButton(
                                tool: tool,
                                action: {
                                    handleToolSelection(tool)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .sheet(item: $selectedTool) { tool in
            ToolDetailView(tool: tool, isPresented: $selectedTool)
        }
    }

    private func handleToolSelection(_ tool: ATAKTool) {
        switch tool.id {
        case "alert":
            selectedTool = tool
        case "brightness":
            showBrightnessControl = true
        case "casevac":
            selectedTool = tool
        case "chat":
            selectedTool = tool
        case "clear":
            // Handle clear content
            break
        default:
            selectedTool = tool
        }
    }
}

// MARK: - Tools Header

struct ToolsHeader: View {
    let onClose: () -> Void

    var body: some View {
        HStack {
            Text("Tools")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            // Edit, List, Settings buttons
            HStack(spacing: 16) {
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                Button(action: {}) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                Button(action: {}) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(Color.black)
    }
}

// MARK: - Tool Button

struct ToolButton: View {
    let tool: ATAKTool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: tool.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(height: 44)

                Text(tool.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 32)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(white: 0.15))
            .overlay(
                Rectangle()
                    .stroke(Color(white: 0.3), lineWidth: 0.5)
            )
        }
    }
}

// MARK: - ATAK Tool Model

struct ATAKTool: Identifiable {
    let id: String
    let displayName: String
    let iconName: String
    let description: String

    static let allTools: [ATAKTool] = [
        // Row 1
        ATAKTool(id: "alert", displayName: "Alert", iconName: "exclamationmark.triangle.fill", description: "Send alerts to team members"),
        ATAKTool(id: "brightness", displayName: "Brightness", iconName: "sun.max.fill", description: "Adjust screen brightness"),
        ATAKTool(id: "casevac", displayName: "CASEVAC", iconName: "cross.case.fill", description: "Request casualty evacuation"),
        ATAKTool(id: "chat", displayName: "Chat", iconName: "message.fill", description: "Team chat messaging"),
        ATAKTool(id: "clear", displayName: "Clear Content", iconName: "trash.fill", description: "Clear map content"),

        // Row 2
        ATAKTool(id: "data", displayName: "Data Packages", iconName: "folder.badge.plus", description: "Manage data packages"),
        ATAKTool(id: "pointer", displayName: "Digital Pointer", iconName: "location.fill", description: "Point to locations"),
        ATAKTool(id: "drawing", displayName: "Drawing Tools", iconName: "pencil.tip.crop.circle", description: "Draw on map"),
        ATAKTool(id: "elevation", displayName: "Elevation", iconName: "mountain.2.fill", description: "View elevation profile"),
        ATAKTool(id: "firstperson", displayName: "First Person", iconName: "eye.fill", description: "First person view"),

        // Row 3
        ATAKTool(id: "gallery", displayName: "Gallery", iconName: "photo.fill", description: "View photo gallery"),
        ATAKTool(id: "geofence", displayName: "Geofence", iconName: "map.circle", description: "Create geofences"),
        ATAKTool(id: "goto", displayName: "GoTo", iconName: "location.north.circle.fill", description: "Navigate to coordinates"),
        ATAKTool(id: "import", displayName: "Import", iconName: "arrow.down.doc.fill", description: "Import data files"),
        ATAKTool(id: "lasso", displayName: "Lasso Select", iconName: "lasso", description: "Select multiple items"),

        // Row 4
        ATAKTool(id: "link", displayName: "Link EUD", iconName: "link", description: "Link end user device"),
        ATAKTool(id: "orientation", displayName: "Orientation", iconName: "location.north.fill", description: "Set map orientation"),
        ATAKTool(id: "plugins", displayName: "Plugins", iconName: "puzzlepiece.extension.fill", description: "Manage plugins"),
        ATAKTool(id: "quicknav", displayName: "Quick Nav", iconName: "signpost.right.fill", description: "Quick navigation"),
        ATAKTool(id: "quickpic", displayName: "Quick Pic", iconName: "camera.fill", description: "Take quick photo")
    ]
}

// MARK: - Tool Detail View

struct ToolDetailView: View {
    let tool: ATAKTool
    @Binding var isPresented: ATAKTool?

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: tool.iconName)
                        .font(.system(size: 80))
                        .foregroundColor(Color(hex: "#FFFC00"))
                        .padding(.top, 40)

                    Text(tool.displayName)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text(tool.description)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Spacer()

                    // Tool-specific content would go here
                    if tool.id == "geofence" {
                        GeofenceToolContent()
                    } else if tool.id == "chat" {
                        ChatToolContent()
                    } else if tool.id == "alert" {
                        AlertToolContent()
                    } else {
                        Text("Coming Soon")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                            .padding()
                    }

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = nil
                    }
                    .foregroundColor(Color(hex: "#FFFC00"))
                }
            }
        }
    }
}

// MARK: - Geofence Tool Content

struct GeofenceToolContent: View {
    @State private var geofenceName = ""
    @State private var radius = 100.0
    @State private var showAlert = true

    var body: some View {
        VStack(spacing: 16) {
            TextField("Geofence Name", text: $geofenceName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            HStack {
                Text("Radius:")
                    .foregroundColor(.white)
                Slider(value: $radius, in: 50...5000, step: 50)
                Text("\(Int(radius))m")
                    .foregroundColor(.white)
                    .frame(width: 60)
            }
            .padding(.horizontal)

            Toggle("Alert on Entry", isOn: $showAlert)
                .foregroundColor(.white)
                .padding(.horizontal)

            Button(action: {}) {
                Text("Create Geofence")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#FFFC00"))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Chat Tool Content

struct ChatToolContent: View {
    @State private var message = ""
    @State private var messages: [SimpleChatMessage] = []

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { msg in
                        SimpleChatBubble(message: msg)
                    }
                }
                .padding()
            }

            HStack(spacing: 12) {
                TextField("Type message...", text: $message)
                    .textFieldStyle(.roundedBorder)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(Color(hex: "#FFFC00"))
                        .font(.system(size: 20))
                }
            }
            .padding()
            .background(Color(white: 0.15))
        }
    }

    private func sendMessage() {
        guard !message.isEmpty else { return }
        messages.append(SimpleChatMessage(text: message, sender: "You", timestamp: Date()))
        message = ""
    }
}

// Simple local message structs for tool demo (not the full ChatMessage from ChatModels.swift)
struct SimpleChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let sender: String
    let timestamp: Date
}

struct SimpleChatBubble: View {
    let message: SimpleChatMessage

    var body: some View {
        HStack {
            if message.sender == "You" {
                Spacer()
            }

            VStack(alignment: message.sender == "You" ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .background(message.sender == "You" ? Color(hex: "#FFFC00") : Color(white: 0.2))
                    .foregroundColor(message.sender == "You" ? .black : .white)
                    .cornerRadius(16)

                Text(message.sender)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }

            if message.sender != "You" {
                Spacer()
            }
        }
    }
}

// MARK: - Alert Tool Content

struct AlertToolContent: View {
    @State private var alertType = "Emergency"
    @State private var message = ""

    let alertTypes = ["Emergency", "Warning", "Information", "Critical"]

    var body: some View {
        VStack(spacing: 16) {
            Picker("Alert Type", selection: $alertType) {
                ForEach(alertTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            TextEditor(text: $message)
                .frame(height: 120)
                .padding(4)
                .background(Color(white: 0.2))
                .cornerRadius(8)
                .padding(.horizontal)

            Button(action: {}) {
                Text("Send Alert")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Color Extension
// Color extension with hex initializer is defined in NavigationDrawer.swift
