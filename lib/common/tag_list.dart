class TagData {
  final String tagEs;
  final String tagEn;
  final String iconPath;

  const TagData({
    required this.tagEs,
    required this.tagEn,
    required this.iconPath,
  });
}

final List<TagData> tagDataList = [
  TagData(
    tagEs: 'Vivienda (Alquiler/Hipoteca)',
    tagEn: 'Housing (Rent/Mortgage)',
    iconPath: 'assets/icons/housing.svg',
  ),
  TagData(
    tagEs: 'Comida (Supermercado)',
    tagEn: 'Food (Grocery)',
    iconPath: 'assets/icons/grocery.svg',
  ),
  TagData(
    tagEs: 'Ocio y Entretenimiento',
    tagEn: 'Leisure and Entertainment',
    iconPath: 'assets/icons/entertainment.svg',
  ),
  TagData(
    tagEs: 'Restaurantes y Bares',
    tagEn: 'Restaurants and Bars',
    iconPath: 'assets/icons/restaurant_bar.svg',
  ),
  TagData(
    tagEs: 'Servicios del Hogar (Agua, Luz, Gas, Internet)',
    tagEn: 'Home Utilities (Water, Electricity, Gas, Internet)',
    iconPath: 'assets/icons/home_utilities.svg',
  ),
  TagData(
    tagEs: 'Transporte (Combustible, Mantenimiento Vehículo, Transporte Público)',
    tagEn: 'Transportation (Fuel, Vehicle Maintenance, Public Transport)',
    iconPath: 'assets/icons/transportation.svg',
  ),
  TagData(
    tagEs: 'Salud (Médico, Farmacia, Seguro)',
    tagEn: 'Health (Medical, Pharmacy, Insurance)',
    iconPath: 'assets/icons/health.svg',
  ),
  TagData(
    tagEs: 'Educación (Cursos, Libros, Matrículas)',
    tagEn: 'Education (Courses, Books, Tuition)',
    iconPath: 'assets/icons/education.svg',
  ),
  TagData(
    tagEs: 'Ropa y Calzado',
    tagEn: 'Clothing and Footwear',
    iconPath: 'assets/icons/clothing.svg',
  ),
  TagData(
    tagEs: 'Cuidado Personal (Peluquería, Cosméticos)',
    tagEn: 'Personal Care (Hairdresser, Cosmetics)',
    iconPath: 'assets/icons/personal_care.svg',
  ),
  TagData(
    tagEs: 'Mascotas',
    tagEn: 'Pets',
    iconPath: 'assets/icons/pets.svg',
  ),
  TagData(
    tagEs: 'Viajes y Vacaciones',
    tagEn: 'Travel and Vacations',
    iconPath: 'assets/icons/travel.svg',
  ),
  TagData(
    tagEs: 'Regalos y Celebraciones',
    tagEn: 'Gifts and Celebrations',
    iconPath: 'assets/icons/gifts.svg',
  ),
  TagData(
    tagEs: 'Mobiliario y Decoración',
    tagEn: 'Furniture and Decoration',
    iconPath: 'assets/icons/furniture.svg',
  ),
  TagData(
    tagEs: 'Reparaciones y Mejoras del Hogar',
    tagEn: 'Home Repairs and Improvements',
    iconPath: 'assets/icons/home_repairs.svg',
  ),
  TagData(
    tagEs: 'Electrónica y Electrodomésticos',
    tagEn: 'Electronics and Appliances',
    iconPath: 'assets/icons/electronics.svg',
  ),
  TagData(
    tagEs: 'Deudas y Préstamos',
    tagEn: 'Debts and Loans',
    iconPath: 'assets/icons/loans.svg',
  ),
  TagData(
    tagEs: 'Impuestos y Tasas',
    tagEn: 'Taxes and Fees',
    iconPath: 'assets/icons/taxes.svg',
  ),
  TagData(
    tagEs: 'Seguros (no de salud ni vehículo)',
    tagEn: 'Insurance (non-health/vehicle)',
    iconPath: 'assets/icons/insurance.svg',
  ),
  TagData(
    tagEs: 'Deportes y Actividades Físicas',
    tagEn: 'Sports and Physical Activities',
    iconPath: 'assets/icons/sports.svg',
  ),
  TagData(
    tagEs: 'Suscripciones (Streaming, Apps, Gimnasio)',
    tagEn: 'Subscriptions (Streaming, Apps, Gym)',
    iconPath: 'assets/icons/subscriptions.svg',
  ),
  TagData(
    tagEs: 'Cultura (Libros, Revistas, Museos)',
    tagEn: 'Culture (Books, Magazines, Museums)',
    iconPath: 'assets/icons/culture.svg',
  ),
  TagData(
    tagEs: 'Tecnología y Software',
    tagEn: 'Technology and Software',
    iconPath: 'assets/icons/software.svg',
  ),
  TagData(
    tagEs: 'Imprevistos',
    tagEn: 'Unexpected Expenses',
    iconPath: 'assets/icons/unexpected.svg',
  ),
  TagData(
    tagEs: 'Ahorro e Inversión',
    tagEn: 'Savings and Investment',
    iconPath: 'assets/icons/savings.svg',
  ),
  TagData(
    tagEs: 'Desarrollo Profesional (Cursos, Talleres)',
    tagEn: 'Professional Development (Courses, Workshops)',
    iconPath: 'assets/icons/professional.svg',
  ),
  TagData(
    tagEs: 'Hijos/Familiares (Gastos específicos)',
    tagEn: 'Children/Family (Specific Expenses)',
    iconPath: 'assets/icons/family.svg',
  ),
  TagData(
    tagEs: 'Donaciones y Caridad',
    tagEn: 'Donations and Charity',
    iconPath: 'assets/icons/donations.svg',
  ),
  TagData(
    tagEs: 'Otros Gastos Misceláneos',
    tagEn: 'Other Miscellaneous Expenses',
    iconPath: 'assets/icons/miscellaneous.svg',
  ),
  TagData(
    tagEs: 'Salario y sueldo',
    tagEn: 'Salary and wages',
    iconPath: 'assets/icons/salary.svg',
  ),
  TagData(
    tagEs: 'Otros ingresos',
    tagEn: 'Other incomes',
    iconPath: 'assets/icons/other_income.svg',
  ),
];


// Function to get the appropriate tag list based on locale
List<String> getTagList(String languageCode) {
  switch (languageCode.toLowerCase()) {
    case 'es':
      return tagDataList.map((tag)=>tag.tagEs).toList();
    case 'en':
    default:
      return tagDataList.map((tag)=>tag.tagEn).toList();
  }
}

String getIconPath(String tag){
  final tagData = tagDataList.firstWhere((data) => data.tagEs == tag || data.tagEn == tag);
  return tagData.iconPath;
}
