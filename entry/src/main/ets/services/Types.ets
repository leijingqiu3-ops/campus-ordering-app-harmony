export interface FoodItem {
  id: string;
  shopId: string;
  name: string;
  price: number;
  category: string;
  desc: string;
  sold: number;
}

export interface ShopItem {
  id: string;
  name: string;
  score: string;
  monthly: string;
  tags: string[];
  foods: FoodItem[];
}