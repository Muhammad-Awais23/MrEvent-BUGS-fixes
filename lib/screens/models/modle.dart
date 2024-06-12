class CarouselItem {
  final String imageUrl;
  final String title;

  CarouselItem({required this.imageUrl, required this.title});

  factory CarouselItem.fromJson(Map<String, dynamic> json) {
    return CarouselItem(
      imageUrl: json['imageUrl'],
      title: json['title'],
    );
  }
}
