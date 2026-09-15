import Foundation

struct FoodRecord: Identifiable, Hashable, Sendable {
    var id: String { name }
    let name: String
    let kcalPer100g: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    var source: String
}

enum NutritionLookup {
    static let commonFoods: [FoodRecord] = [
        FoodRecord(name: "Chicken Breast, Grilled", kcalPer100g: 165, protein: 31, carbs: 0, fat: 3.6, source: "USDA"),
        FoodRecord(name: "Chicken Thigh, Roasted", kcalPer100g: 209, protein: 26, carbs: 0, fat: 10.9, source: "USDA"),
        FoodRecord(name: "White Rice, Cooked", kcalPer100g: 130, protein: 2.7, carbs: 28, fat: 0.3, source: "USDA"),
        FoodRecord(name: "Brown Rice, Cooked", kcalPer100g: 123, protein: 2.7, carbs: 26, fat: 1, source: "USDA"),
        FoodRecord(name: "Fried Rice", kcalPer100g: 163, protein: 4.5, carbs: 24, fat: 5.4, source: "USDA"),
        FoodRecord(name: "Noodles, Cooked", kcalPer100g: 138, protein: 4.5, carbs: 26, fat: 1.5, source: "USDA"),
        FoodRecord(name: "Beef Noodle Soup (Pho)", kcalPer100g: 82, protein: 6, carbs: 9, fat: 2.2, source: "USDA"),
        FoodRecord(name: "Pad Thai", kcalPer100g: 181, protein: 8, carbs: 25, fat: 6, source: "USDA"),
        FoodRecord(name: "Spaghetti with Tomato Sauce", kcalPer100g: 128, protein: 4.8, carbs: 21, fat: 3, source: "USDA"),
        FoodRecord(name: "Spaghetti Bolognese", kcalPer100g: 158, protein: 8, carbs: 18, fat: 5.8, source: "USDA"),
        FoodRecord(name: "Pizza, Cheese", kcalPer100g: 266, protein: 11, carbs: 33, fat: 10, source: "USDA"),
        FoodRecord(name: "Cheeseburger", kcalPer100g: 254, protein: 13, carbs: 22, fat: 12.5, source: "USDA"),
        FoodRecord(name: "French Fries", kcalPer100g: 312, protein: 3.4, carbs: 41, fat: 15, source: "USDA"),
        FoodRecord(name: "Fried Chicken", kcalPer100g: 290, protein: 22, carbs: 12, fat: 17, source: "USDA"),
        FoodRecord(name: "Salmon, Baked", kcalPer100g: 208, protein: 20, carbs: 0, fat: 13, source: "USDA"),
        FoodRecord(name: "Tuna, Canned in Water", kcalPer100g: 116, protein: 26, carbs: 0, fat: 1, source: "USDA"),
        FoodRecord(name: "Shrimp, Cooked", kcalPer100g: 99, protein: 24, carbs: 0.2, fat: 0.3, source: "USDA"),
        FoodRecord(name: "Pork Belly, Braised", kcalPer100g: 518, protein: 9, carbs: 0, fat: 53, source: "USDA"),
        FoodRecord(name: "Egg, Boiled", kcalPer100g: 155, protein: 13, carbs: 1.1, fat: 11, source: "USDA"),
        FoodRecord(name: "Egg, Fried", kcalPer100g: 196, protein: 14, carbs: 0.8, fat: 15, source: "USDA"),
        FoodRecord(name: "Tofu, Firm", kcalPer100g: 144, protein: 17, carbs: 3, fat: 9, source: "USDA"),
        FoodRecord(name: "Mapo Tofu", kcalPer100g: 128, protein: 9, carbs: 4, fat: 9, source: "USDA"),
        FoodRecord(name: "Dumplings, Pork (Boiled)", kcalPer100g: 210, protein: 8.5, carbs: 26, fat: 8, source: "USDA"),
        FoodRecord(name: "Sushi Roll, Salmon", kcalPer100g: 145, protein: 6.5, carbs: 21, fat: 3.5, source: "USDA"),
        FoodRecord(name: "Bibimbap", kcalPer100g: 132, protein: 5.5, carbs: 18, fat: 4, source: "USDA"),
        FoodRecord(name: "Greek Yogurt, Plain", kcalPer100g: 59, protein: 10, carbs: 3.6, fat: 0.4, source: "USDA"),
        FoodRecord(name: "Whole Milk", kcalPer100g: 61, protein: 3.2, carbs: 4.8, fat: 3.3, source: "USDA"),
        FoodRecord(name: "Oatmeal, Cooked", kcalPer100g: 71, protein: 2.5, carbs: 12, fat: 1.5, source: "USDA"),
        FoodRecord(name: "Whole Wheat Bread", kcalPer100g: 247, protein: 13, carbs: 41, fat: 3.4, source: "USDA"),
        FoodRecord(name: "Bagel, Plain", kcalPer100g: 257, protein: 10, carbs: 50, fat: 1.5, source: "USDA"),
        FoodRecord(name: "Banana", kcalPer100g: 89, protein: 1.1, carbs: 23, fat: 0.3, source: "USDA"),
        FoodRecord(name: "Apple", kcalPer100g: 52, protein: 0.3, carbs: 14, fat: 0.2, source: "USDA"),
        FoodRecord(name: "Orange", kcalPer100g: 47, protein: 0.9, carbs: 12, fat: 0.1, source: "USDA"),
        FoodRecord(name: "Avocado", kcalPer100g: 160, protein: 2, carbs: 8.5, fat: 15, source: "USDA"),
        FoodRecord(name: "Broccoli, Steamed", kcalPer100g: 35, protein: 2.4, carbs: 7, fat: 0.4, source: "USDA"),
        FoodRecord(name: "Mixed Salad Greens", kcalPer100g: 17, protein: 1.4, carbs: 3.3, fat: 0.2, source: "USDA"),
        FoodRecord(name: "Caesar Salad with Dressing", kcalPer100g: 190, protein: 6, carbs: 6, fat: 16, source: "USDA"),
        FoodRecord(name: "Tomato", kcalPer100g: 18, protein: 0.9, carbs: 3.9, fat: 0.2, source: "USDA"),
        FoodRecord(name: "Baked Potato", kcalPer100g: 93, protein: 2.5, carbs: 21, fat: 0.1, source: "USDA"),
        FoodRecord(name: "Mashed Potatoes with Butter", kcalPer100g: 113, protein: 2, carbs: 17, fat: 4.2, source: "USDA"),
        FoodRecord(name: "Sweet Potato, Baked", kcalPer100g: 90, protein: 2, carbs: 21, fat: 0.1, source: "USDA"),
        FoodRecord(name: "Burrito, Beef & Bean", kcalPer100g: 206, protein: 9, carbs: 24, fat: 8, source: "USDA"),
        FoodRecord(name: "Taco, Beef", kcalPer100g: 226, protein: 12, carbs: 20, fat: 11, source: "USDA"),
        FoodRecord(name: "Hummus", kcalPer100g: 166, protein: 7.9, carbs: 14, fat: 9.6, source: "USDA"),
        FoodRecord(name: "Peanut Butter", kcalPer100g: 588, protein: 25, carbs: 20, fat: 50, source: "USDA"),
        FoodRecord(name: "Almonds", kcalPer100g: 579, protein: 21, carbs: 22, fat: 50, source: "USDA"),
        FoodRecord(name: "Cheddar Cheese", kcalPer100g: 403, protein: 25, carbs: 1.3, fat: 33, source: "USDA"),
        FoodRecord(name: "Mozzarella, Fresh", kcalPer100g: 280, protein: 22, carbs: 2.2, fat: 17, source: "USDA"),
        FoodRecord(name: "Milk Tea with Sugar", kcalPer100g: 78, protein: 1.5, carbs: 13, fat: 2.2, source: "USDA"),
        FoodRecord(name: "Bubble Milk Tea", kcalPer100g: 108, protein: 1.2, carbs: 20, fat: 2.5, source: "USDA"),
        FoodRecord(name: "Black Coffee", kcalPer100g: 1, protein: 0.1, carbs: 0, fat: 0, source: "USDA"),
        FoodRecord(name: "Latte with Whole Milk", kcalPer100g: 55, protein: 3, carbs: 5, fat: 2.9, source: "USDA"),
        FoodRecord(name: "Cola", kcalPer100g: 41, protein: 0, carbs: 10.6, fat: 0, source: "USDA"),
        FoodRecord(name: "Orange Juice", kcalPer100g: 45, protein: 0.7, carbs: 10.4, fat: 0.2, source: "USDA"),
        FoodRecord(name: "Beer", kcalPer100g: 43, protein: 0.5, carbs: 3.6, fat: 0, source: "USDA"),
        FoodRecord(name: "Red Wine", kcalPer100g: 85, protein: 0.1, carbs: 2.6, fat: 0, source: "USDA"),
        FoodRecord(name: "Chocolate Cake", kcalPer100g: 371, protein: 4, carbs: 51, fat: 17, source: "USDA"),
        FoodRecord(name: "Chocolate Chip Cookie", kcalPer100g: 488, protein: 5.7, carbs: 64, fat: 24, source: "USDA"),
        FoodRecord(name: "Ice Cream, Vanilla", kcalPer100g: 207, protein: 3.5, carbs: 24, fat: 11, source: "USDA"),
        FoodRecord(name: "Miso Soup", kcalPer100g: 33, protein: 2.2, carbs: 3, fat: 1, source: "USDA"),
        FoodRecord(name: "Hot and Sour Soup", kcalPer100g: 55, protein: 3, carbs: 6, fat: 2, source: "USDA"),
        FoodRecord(name: "Wonton Soup", kcalPer100g: 78, protein: 5, carbs: 9, fat: 2.2, source: "USDA"),
        FoodRecord(name: "Kimchi", kcalPer100g: 15, protein: 1.1, carbs: 2.4, fat: 0.5, source: "USDA"),
        FoodRecord(name: "Roast Duck", kcalPer100g: 337, protein: 19, carbs: 0, fat: 28, source: "USDA"),
        FoodRecord(name: "Char Siu Pork", kcalPer100g: 250, protein: 22, carbs: 8, fat: 14, source: "USDA"),
        FoodRecord(name: "Kung Pao Chicken", kcalPer100g: 172, protein: 13, carbs: 8, fat: 10, source: "USDA"),
        FoodRecord(name: "Sweet and Sour Pork", kcalPer100g: 195, protein: 11, carbs: 15, fat: 10, source: "USDA"),
        FoodRecord(name: "Steamed Fish with Ginger", kcalPer100g: 118, protein: 18, carbs: 1.5, fat: 4.5, source: "USDA"),
        FoodRecord(name: "Lamb Kebab", kcalPer100g: 232, protein: 18, carbs: 2, fat: 16, source: "USDA"),
        FoodRecord(name: "Butter Chicken", kcalPer100g: 189, protein: 11, carbs: 5, fat: 14, source: "USDA"),
        FoodRecord(name: "Chicken Tikka Masala", kcalPer100g: 162, protein: 12, carbs: 5, fat: 10, source: "USDA"),
        FoodRecord(name: "Chana Masala", kcalPer100g: 130, protein: 5.5, carbs: 17, fat: 4.5, source: "USDA"),
        FoodRecord(name: "Falafel", kcalPer100g: 333, protein: 13, carbs: 32, fat: 18, source: "USDA"),
        FoodRecord(name: "Ramen, Tonkotsu", kcalPer100g: 110, protein: 5.5, carbs: 12, fat: 4.5, source: "USDA"),
        FoodRecord(name: "Gyoza, Pan-Fried", kcalPer100g: 220, protein: 9, carbs: 24, fat: 10, source: "USDA"),
        FoodRecord(name: "Tempura Shrimp", kcalPer100g: 245, protein: 12, carbs: 21, fat: 13, source: "USDA"),
        FoodRecord(name: "Pancakes with Syrup", kcalPer100g: 227, protein: 5.5, carbs: 38, fat: 6, source: "USDA"),
        FoodRecord(name: "Bacon", kcalPer100g: 541, protein: 37, carbs: 1.4, fat: 42, source: "USDA"),
        FoodRecord(name: "Sausage, Pork", kcalPer100g: 301, protein: 18, carbs: 2, fat: 25, source: "USDA"),
        FoodRecord(name: "Ham Sandwich", kcalPer100g: 220, protein: 11, carbs: 25, fat: 8, source: "USDA"),
        FoodRecord(name: "Chicken Caesar Wrap", kcalPer100g: 215, protein: 13, carbs: 22, fat: 8.5, source: "USDA"),
        FoodRecord(name: "Protein Shake, Whey in Water", kcalPer100g: 40, protein: 8, carbs: 1.5, fat: 0.5, source: "USDA"),
        FoodRecord(name: "Cottage Cheese, 2%", kcalPer100g: 84, protein: 11, carbs: 4.3, fat: 2.3, source: "USDA"),
        FoodRecord(name: "Edamame", kcalPer100g: 121, protein: 12, carbs: 9, fat: 5, source: "USDA"),
        FoodRecord(name: "Corn on the Cob", kcalPer100g: 96, protein: 3.4, carbs: 21, fat: 1.5, source: "USDA"),
        FoodRecord(name: "Clam Chowder", kcalPer100g: 88, protein: 3.5, carbs: 9, fat: 4, source: "USDA"),
        FoodRecord(name: "Steak, Sirloin", kcalPer100g: 206, protein: 30, carbs: 0, fat: 9, source: "USDA"),
        FoodRecord(name: "Pork Chop, Grilled", kcalPer100g: 231, protein: 26, carbs: 0, fat: 13, source: "USDA"),
        FoodRecord(name: "Turkey, Roasted", kcalPer100g: 135, protein: 29, carbs: 0, fat: 1, source: "USDA"),
        FoodRecord(name: "Meatballs with Sauce", kcalPer100g: 185, protein: 12, carbs: 8, fat: 11, source: "USDA"),
        FoodRecord(name: "Lasagna", kcalPer100g: 132, protein: 8, carbs: 13, fat: 5, source: "USDA"),
        FoodRecord(name: "Fried Noodles with Vegetables", kcalPer100g: 186, protein: 5, carbs: 26, fat: 7, source: "USDA"),
        FoodRecord(name: "Spring Rolls, Fried", kcalPer100g: 250, protein: 6, carbs: 26, fat: 14, source: "USDA"),
        FoodRecord(name: "Congee, Rice Porridge", kcalPer100g: 35, protein: 1, carbs: 7.5, fat: 0.2, source: "USDA"),
        FoodRecord(name: "Baozi, Pork Steamed Bun", kcalPer100g: 227, protein: 8.5, carbs: 34, fat: 6.5, source: "USDA"),
        FoodRecord(name: "Jianbing, Chinese Crepe", kcalPer100g: 240, protein: 8, carbs: 30, fat: 9.5, source: "USDA"),
        FoodRecord(name: "Stir-Fried Vegetables with Oil", kcalPer100g: 95, protein: 2.5, carbs: 8, fat: 6.5, source: "USDA")
    ]

    static func search(_ query: String) -> [FoodRecord] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return commonFoods.filter { $0.name.lowercased().contains(q) }
    }

    static func nutrition(forGrams grams: Double, of record: FoodRecord) -> (kcal: Double, protein: Double, carbs: Double, fat: Double) {
        let factor = grams / 100.0
        return (record.kcalPer100g * factor, record.protein * factor, record.carbs * factor, record.fat * factor)
    }

    static func fetchBarcode(_ barcode: String) async -> FoodRecord? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? Int, status == 1,
                  let product = json["product"] as? [String: Any],
                  let name = (product["product_name_en"] ?? product["product_name"]) as? String, !name.isEmpty,
                  let nutriments = product["nutriments"] as? [String: Any] else { return nil }
            let kcal = Self.num(nutriments["energy-kcal_100g"]) ?? (Self.num(nutriments["energy_100g"]).map { $0 / 4.184 }) ?? 0
            let protein = Self.num(nutriments["proteins_100g"]) ?? 0
            let carbs = Self.num(nutriments["carbohydrates_100g"]) ?? 0
            let fat = Self.num(nutriments["fat_100g"]) ?? 0
            return FoodRecord(name: name, kcalPer100g: kcal, protein: protein, carbs: carbs, fat: fat, source: "OFF")
        } catch {
            return nil
        }
    }

    private static func num(_ any: Any?) -> Double? {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let s = any as? String { return Double(s) }
        return nil
    }
}
