// Spanish tags list
List<String> SpanishTagList = [
  'Vivienda (Alquiler/Hipoteca)',
  'Comida (Supermercado)',
  'Ocio y Entretenimiento',
  'Restaurantes y Bares',
  'Servicios del Hogar (Agua, Luz, Gas, Internet)',
  'Transporte (Combustible, Mantenimiento Vehículo, Transporte Público)',
  'Salud (Médico, Farmacia, Seguro)',
  'Educación (Cursos, Libros, Matrículas)',
  'Ropa y Calzado',
  'Cuidado Personal (Peluquería, Cosméticos)',
  'Mascotas',
  'Viajes y Vacaciones',
  'Regalos y Celebraciones',
  'Mobiliario y Decoración',
  'Reparaciones y Mejoras del Hogar',
  'Electrónica y Electrodomésticos',
  'Deudas y Préstamos',
  'Impuestos y Tasas',
  'Seguros (no de salud ni vehículo)',
  'Deportes y Actividades Físicas',
  'Suscripciones (Streaming, Apps, Gimnasio)',
  'Cultura (Libros, Revistas, Museos)',
  'Tecnología y Software',
  'Imprevistos',
  'Ahorro e Inversión',
  'Desarrollo Profesional (Cursos, Talleres)',
  'Hijos/Familiares (Gastos específicos)',
  'Donaciones y Caridad',
  'Otros Gastos Misceláneos',
];

// English tags list
List<String> EnglishTagList = [
  'Housing (Rent/Mortgage)',
  'Food (Grocery)',
  'Leisure and Entertainment',
  'Restaurants and Bars',
  'Home Utilities (Water, Electricity, Gas, Internet)',
  'Transportation (Fuel, Vehicle Maintenance, Public Transport)',
  'Health (Medical, Pharmacy, Insurance)',
  'Education (Courses, Books, Tuition)',
  'Clothing and Footwear',
  'Personal Care (Hairdresser, Cosmetics)',
  'Pets',
  'Travel and Vacations',
  'Gifts and Celebrations',
  'Furniture and Decoration',
  'Home Repairs and Improvements',
  'Electronics and Appliances',
  'Debts and Loans',
  'Taxes and Fees',
  'Insurance (non-health/vehicle)',
  'Sports and Physical Activities',
  'Subscriptions (Streaming, Apps, Gym)',
  'Culture (Books, Magazines, Museums)',
  'Technology and Software',
  'Unexpected Expenses',
  'Savings and Investment',
  'Professional Development (Courses, Workshops)',
  'Children/Family (Specific Expenses)',
  'Donations and Charity',
  'Other Miscellaneous Expenses',
];

// Function to get the appropriate tag list based on locale
List<String> getTagList(String languageCode) {
  switch (languageCode.toLowerCase()) {
    case 'es':
      return SpanishTagList;
    case 'en':
    default:
      return EnglishTagList;
  }
}
