void main() {
  String? s;
  try {
    print(s.toString());
  } catch (e) {
    print('Error: $e');
  }
}
