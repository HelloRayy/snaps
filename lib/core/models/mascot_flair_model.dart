/// Supported mascot bundles and emotions from page-mascot (SNAPS-13)
enum MascotBundle {
  bear('Bear', 'assets/mascots/bear'),
  bunny('Bunny', 'assets/mascots/bunny'),
  cat('Cat', 'assets/mascots/cat'),
  deer('Deer', 'assets/mascots/deer'),
  dino('Dino', 'assets/mascots/dino'),
  fox('Fox', 'assets/mascots/fox'),
  frog('Frog', 'assets/mascots/frog'),
  hamster('Hamster', 'assets/mascots/hamster'),
  hedgehog('Hedgehog', 'assets/mascots/hedgehog'),
  koala('Koala', 'assets/mascots/koala'),
  mouse('Mouse', 'assets/mascots/mouse'),
  otter('Otter', 'assets/mascots/otter'),
  owl('Owl', 'assets/mascots/owl'),
  panda('Panda', 'assets/mascots/panda'),
  penguin('Penguin', 'assets/mascots/penguin'),
  pug('Pug', 'assets/mascots/pug'),
  raccoon('Raccoon', 'assets/mascots/raccoon'),
  redpanda('Red Panda', 'assets/mascots/redpanda'),
  sheep('Sheep', 'assets/mascots/sheep'),
  sloth('Sloth', 'assets/mascots/sloth'),
  tiger('Tiger', 'assets/mascots/tiger');

  final String label;
  final String basePath;
  const MascotBundle(this.label, this.basePath);

  static MascotBundle? fromString(String? val) {
    if (val == null) return null;
    for (final b in MascotBundle.values) {
      if (b.name.toLowerCase() == val.toLowerCase()) return b;
    }
    return null;
  }
}

enum MascotEmotion {
  blink('Blink', 'blink.webp'),
  heart('Love', 'heart.webp'),
  sparkle('Sparkle', 'sparkle.webp'),
  surprised('Surprised', 'surprised.webp'),
  wink('Wink', 'wink.webp'),
  bashful('Bashful', 'bashful.webp'),
  sleepy('Sleepy', 'sleepy.webp'),
  dizzy('Dizzy', 'dizzy.webp'),
  delighted('Happy', 'delighted.webp');

  final String label;
  final String fileName;
  const MascotEmotion(this.label, this.fileName);

  static MascotEmotion? fromString(String? val) {
    if (val == null) return null;
    for (final e in MascotEmotion.values) {
      if (e.name.toLowerCase() == val.toLowerCase()) return e;
    }
    return null;
  }
}

/// Metadata model for user flair mascot badge
class MascotFlairModel {
  final MascotBundle bundle;
  final MascotEmotion emotion;

  const MascotFlairModel({
    required this.bundle,
    required this.emotion,
  });

  String get assetPath => '${bundle.basePath}/${emotion.fileName}';

  factory MascotFlairModel.fromJson(Map<String, dynamic> json) {
    final b = MascotBundle.fromString(json['bundle']?.toString()) ?? MascotBundle.koala;
    final e = MascotEmotion.fromString(json['emotion']?.toString()) ?? MascotEmotion.delighted;
    return MascotFlairModel(bundle: b, emotion: e);
  }

  Map<String, dynamic> toJson() {
    return {
      'bundle': bundle.name,
      'emotion': emotion.name,
    };
  }
}
