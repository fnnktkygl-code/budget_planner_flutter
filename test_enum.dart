enum ButtonType {
  standard('standard'),
  icon('icon');

  const ButtonType(String type) : _type = type;
  final String _type;
}

void main() {
  print(ButtonType.standard.toString());
  // Let's test the map
  Map<ButtonType, String> myMap = {
    ButtonType.standard: 'std',
  };
  
  // This simulates what google_sign_in_web does
  dynamic t = ButtonType.standard;
  print(myMap[t]);
}
