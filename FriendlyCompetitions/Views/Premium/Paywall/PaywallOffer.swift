struct PaywallOffer: Identifiable {
    let product: Product
    let selected: Bool

    var id: Product.ID { product.id }
}
