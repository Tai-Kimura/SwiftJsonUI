//
//  DynamicCollectionViews.swift
//  SwiftJsonUI
//
//  Dynamic collection components
//

import SwiftUI

struct DynamicCollectionView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        if let items = component.items {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
}

struct DynamicTableView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        if let data = component.data {
            ScrollView {
                VStack(spacing: 1) {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, row in
                        HStack {
                            ForEach(Array(row.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                                Text(value)
                                    .frame(maxWidth: .infinity)
                                    .padding(8)
                            }
                        }
                        .background(Color.gray.opacity(0.1))
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
}