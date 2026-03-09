//
//  ContentView.swift
//  CipherDen
//
//  Created by hyperlink on 23/01/26.
//

import SwiftUI

struct ContentView: View {
    
    @State private var showCopyToast = false
    @StateObject var vm = CryptoViewModel()

    var body: some View {
        
        ZStack {
            
            VStack(spacing: 14) {
                
                Text("CipherDen")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Input JSON / Text").font(.headline)
                    EditableTextView(text: $vm.inputText)
                        .frame(height: 180)
                }
                
                // Password
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password / Secret Key").font(.headline)
                    
                    HStack {
                        if vm.isPasswordVisible {
                            TextField("Enter password", text: $vm.password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            SecureField("Enter password", text: $vm.password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Button {
                            vm.isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: vm.isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Buttons
                HStack(spacing: 16) {
                    Button("Encrypt") { vm.encrypt() }
                    Button("Decrypt") { vm.decrypt() }
                    
                    Button {
                        vm.clearAll()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }.foregroundColor(.red)
                    
                }
                
                // Result
                VStack(alignment: .leading, spacing: 6) {
                    
                    HStack {
                        Text("Result Output")
                            .font(.headline)
                        
                        Spacer()
                        
                        if !vm.outputText.isEmpty {
                            Button {
                                copyToClipboard(vm.outputText)
                                
                                withAnimation {
                                    showCopyToast = true
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        showCopyToast = false
                                    }
                                }
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: vm.outputText.isEmpty)
                    
                    ReadOnlyTextView(text: $vm.outputText)
                        .frame(height: 180)
                }
                
                // Status
                if !vm.copyStatus.isEmpty {
                    Text(vm.copyStatus).foregroundColor(.green)
                }
                
                if !vm.errorMessage.isEmpty {
                    Text(vm.errorMessage).foregroundColor(.red)
                }
            }
            .padding()
            .frame(width: 600, height: 700)
            .overlay(alignment: .top) {
                if showCopyToast {
                    CopyToastView()
                        .padding(.top, 12) // distance from window top
                        .transition(
                            .move(edge: .top)
                            .combined(with: .opacity)
                        )
                        .zIndex(100)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: showCopyToast)
        }
    }
}

#Preview {
    ContentView()
}
