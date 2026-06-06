class ImageItem {
  final String url;
  final String data; // base64 string

  ImageItem({required this.url, required this.data});

  factory ImageItem.fromJson(Map<String, dynamic> json) {
    return ImageItem(
      url: json['url'] ?? '',
      data: json['data'] ?? '',
    );
  }
}

class ImagesResponse {
  final List<ImageItem> images;

  ImagesResponse({required this.images});

  factory ImagesResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['images'] as List<dynamic>?) ?? [];
    return ImagesResponse(
      images: list.whereType<Map<String, dynamic>>().map(ImageItem.fromJson).toList(),
    );
  }
}
