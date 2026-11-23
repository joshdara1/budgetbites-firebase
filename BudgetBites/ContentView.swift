//
//  ContentView.swift
//  BudgetBites
//
//  Created by Joshua Daramola on 24/03/2026.
//

import SwiftUI
import FirebaseFirestore

// I created this model to keep each grocery item structured and easy to manage in lists and calculations.
struct GroceryItem: Identifiable {
    let id = UUID()
    let name: String
    let price: Double
}

// I introduced this model to organise meal data cleanly and make the feature easier to extend later.
struct Meal: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let ingredients: [String]
    let costLabel: String
}

struct ContentView: View {
    // I store items in state so the UI updates automatically when items are added or removed.
    @State private var groceryItems: [GroceryItem] = []

    // I store the budget using AppStorage so it persists even after the app is closed and reopened.
    @AppStorage("savedBudget") private var budget: String = ""
    
    // I used this Firestore reference to reset app data
    private let db = Firestore.firestore()

    // I calculate this dynamically so it always reflects the latest list changes.
    var totalSpent: Double {
        groceryItems.reduce(0) { $0 + $1.price }
    }

    // I calculate this to give users more insight into their spending behaviour.
    var averagePrice: Double {
        groceryItems.isEmpty ? 0 : totalSpent / Double(groceryItems.count)
    }

    // I convert the text input into a number so it can be used in calculations safely.
    var budgetAmount: Double {
        Double(budget) ?? 0
    }

    // I ensure this never goes below zero to avoid confusing negative values.
    var remainingBudget: Double {
        max(budgetAmount - totalSpent, 0)
    }

    // I normalise this value between 0 and 1 for use in the progress bar UI.
    var progressValue: Double {
        guard budgetAmount > 0 else { return 0 }
        return min(totalSpent / budgetAmount, 1)
    }

    // I use this to clear grocery data from both Firestore and local storage.
    private func resetGroceryData() {
        db.collection("groceryItems").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching documents to reset: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("No documents found to delete.")
                groceryItems = []
                return
            }

            for document in documents {
                db.collection("groceryItems").document(document.documentID).delete { error in
                    if let error = error {
                        print("Error deleting document: \(error.localizedDescription)")
                    }
                }
            }

            // I also clear the local list so the UI updates immediately.
            groceryItems = []
        }
    }
    
    
    var body: some View {
        TabView {
            HomeView(
                totalSpent: totalSpent,
                itemCount: groceryItems.count,
                budget: $budget,
                remainingBudget: remainingBudget,
                progressValue: progressValue
            )
            .tabItem {
                Label("Home", systemImage: "house")
            }

            GroceryListView(groceryItems: $groceryItems)
                .tabItem {
                    Label("Grocery", systemImage: "cart")
                }

            InsightsView(
                itemCount: groceryItems.count,
                totalSpent: totalSpent,
                averagePrice: averagePrice,
                remainingBudget: remainingBudget
            )
            .tabItem {
                Label("Insights", systemImage: "chart.bar")
            }

            SettingsView(resetGroceryData: resetGroceryData)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.green)
    }
}

struct GroceryListView: View {
    // I store temporary input here before creating a new item.
    @State private var itemName = ""

    // I store temporary price input here before validation.
    @State private var itemPrice = ""

    // I use binding so changes here reflect in the parent view instantly.
    @Binding var groceryItems: [GroceryItem]

    // I initialise Firestore once here so I can reuse it when saving items.
    private let db = Firestore.firestore()

    // I build the grocery list screen UI here.
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Grocery List")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("Enter Item Name", text: $itemName)
                    .textFieldStyle(.roundedBorder)

                TextField("Enter Item Price", text: $itemPrice)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                Button {
                    addItem()
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)

                List {
                    ForEach(groceryItems) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.headline)

                            Text("£\(String(format: "%.2f", item.price))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteItem)
                }
            }
            .padding()
        }
        .onAppear {
            loadItems()
        }
    }

    // I handle validation, local state update, and cloud persistence in one place.
    private func addItem() {
        // I guard against invalid input to prevent crashes or bad data.
        guard !itemName.isEmpty, let price = Double(itemPrice) else { return }

        // I update locally first so the UI feels responsive.
        let newItem = GroceryItem(name: itemName, price: price)
        groceryItems.append(newItem)

        // I persist data to Firestore so it can be extended for cross-device use later.
        db.collection("groceryItems").addDocument(data: [
            "name": newItem.name,
            "price": newItem.price,
            "timestamp": Timestamp()
        ]) { error in
            if let error = error {
                print("Error saving item to Firestore: \(error.localizedDescription)")
            } else {
                print("Item saved to Firestore successfully")
            }
        }

        // I reset inputs to improve usability after adding an item.
        itemName = ""
        itemPrice = ""
    }

    // I fetch saved grocery items from Firestore so the list can be restored when the screen opens.
    private func loadItems() {
        db.collection("groceryItems")
            .order(by: "timestamp", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading items from Firestore: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No grocery items found in Firestore.")
                    return
                }

                let fetchedItems = documents.map { document -> GroceryItem in
                    let data = document.data()
                    let name = data["name"] as? String ?? "Unnamed Item"
                    let price = data["price"] as? Double ?? 0.0
                    return GroceryItem(name: name, price: price)
                }

                // I replace the local list with the fetched data to avoid duplicates.
                groceryItems = fetchedItems
            }
    }

    // I remove items directly from state so the list updates automatically.
    private func deleteItem(at offsets: IndexSet) {
        groceryItems.remove(atOffsets: offsets)
    }
}

struct InsightsView: View {
    let itemCount: Int
    let totalSpent: Double
    let averagePrice: Double
    let remainingBudget: Double

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Insights")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Total Items: \(itemCount)")
                Text("Total Spent: £\(String(format: "%.2f", totalSpent))")
                Text("Average Item Price: £\(String(format: "%.2f", averagePrice))")
                Text("Remaining Budget: £\(String(format: "%.2f", remainingBudget))")
            }
            .padding()
        }
    }
}

struct SettingsView: View {
    // I pass this action in so the Settings screen can trigger a full grocery reset.
    let resetGroceryData: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("BudgetBites v1.0")
                    .foregroundColor(.gray)

                Button(role: .destructive) {
                    resetGroceryData()
                } label: {
                    Label("Reset Grocery List", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

struct HomeView: View {
    // These values are passed down to keep HomeView focused on presentation only.
    let totalSpent: Double
    let itemCount: Int

    // I allow editing here while keeping a single source of truth in ContentView.
    @Binding var budget: String

    // Calculated remaining budget and progress bar value.
    let remainingBudget: Double
    let progressValue: Double

    var body: some View {
        NavigationStack {
            // I added scrolling to prevent layout issues as more features were added.
            ScrollView {
                VStack(spacing: 24) {
                Text("Budget Overview")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                ProgressBar(progress: progressValue)
                    .frame(width: 170, height: 170)

                TextField("Enter Budget", text: $budget)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                VStack(spacing: 12) {
                    infoCard(title: "Items in Grocery List", value: "\(itemCount)")
                    infoCard(title: "Total Spent", value: "£\(String(format: "%.2f", totalSpent))")
                    infoCard(title: "Remaining Budget", value: "£\(String(format: "%.2f", remainingBudget))")
                }

                // I added this to improve user guidance without adding complexity.
                tipCard(text: "Plan your meals for the week before shopping to reduce impulse spending.")

                // Button that navigates to the Meal Ideas screen.
                NavigationLink {
                    MealIdeasView()
                } label: {
                    Label("View Meal Ideas", systemImage: "fork.knife")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                }
                .padding()
            }
        }
    }

    // I extracted this to reduce duplication and keep the UI consistent.
    private func infoCard(title: String, value: String) -> some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // I added this to improve user guidance without adding complexity.
    private func tipCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Budget Tip")
                .font(.headline)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemYellow).opacity(0.2))
        .cornerRadius(12)
    }
}

// I separated this into its own view to keep navigation clean and modular.
struct MealIdeasView: View {
    // I used static data here to keep implementation simple while demonstrating the feature.
    let meals: [Meal] = [
        Meal(
            name: "Jollof Rice",
            description: "Budget-friendly classic",
            ingredients: ["Rice", "Tomatoes", "Pepper", "Onion"],
            costLabel: "Low cost"
        ),
        Meal(
            name: "Pasta Bake",
            description: "Quick and filling",
            ingredients: ["Pasta", "Cheese", "Tomato sauce"],
            costLabel: "Around £5"
        ),
        Meal(
            name: "Chicken Stir Fry",
            description: "Easy midweek meal",
            ingredients: ["Chicken", "Vegetables", "Soy sauce"],
            costLabel: "Around £6/7"
        ),
        Meal(
            name: "Beans on Toast",
            description: "Simple low-cost option and extremely versatile",
            ingredients: ["Bread", "Baked beans", "Butter", "Cheese (optional)"],
            costLabel: "Very low cost"
        )
    ]

    var body: some View {
        NavigationStack {
            List(meals) { meal in
                VStack(alignment: .leading, spacing: 8) {
                    Text(meal.name)
                        .font(.headline)

                    Text(meal.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("Estimated Cost: \(meal.costLabel)")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Text("Ingredients")
                        .font(.caption)
                        .fontWeight(.bold)

                    ForEach(meal.ingredients, id: \.self) { ingredient in
                        Text("• \(ingredient)")
                            .font(.caption)
                    }
                }
                .padding(.vertical, 6)
            }
            .navigationTitle("Meal Ideas")
        }
    }
}

// I created this reusable component to visualise budget usage clearly.
struct ProgressBar: View {
    let progress: Double
    var color: Color = .green

    // I animate this to improve user experience and feedback.
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 18)
                .opacity(0.2)
                .foregroundColor(.gray)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    style: StrokeStyle(
                        lineWidth: 18,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .foregroundColor(color)
                .rotationEffect(.degrees(270))

            Text("\(Int(progress * 100))%")
                .font(.title2)
                .fontWeight(.bold)
        }
        .animation(.easeInOut(duration: 0.6), value: progress)
    }
}

#Preview {
    ContentView()
}
