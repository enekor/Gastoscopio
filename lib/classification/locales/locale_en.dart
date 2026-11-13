import 'locale_config.dart';

final localeEn = LocaleConfig(
  localeCode: 'en',
  expensePatterns: [
    RegExp(r'[Cc]ard\s+purchase.*?at\s+(.+?)\s+(?:for\s+)?\$?([\d.,]+)', caseSensitive: false),
    RegExp(r'[Pp]ayment\s+to\s+(.+?)\s+\$?([\d.,]+)', caseSensitive: false),
    RegExp(r'[Dd]irect\s+debit.*?\s+(.+?)\s+\$?([\d.,]+)', caseSensitive: false),
    RegExp(r'[Cc]harge\s+(?:from|by)\s+(.+?)\s+\$?([\d.,]+)', caseSensitive: false),
    RegExp(r'[Pp]\.?[Oo]\.?[Ss]\.?\s+(?:purchase\s+)?(.+?)\s+\$?([\d.,]+)', caseSensitive: false),
    RegExp(r'[Aa][Tt][Mm]\s+withdrawal.*?\$?([\d.,]+)', caseSensitive: false),
    RegExp(r'[Dd]ebit.*?(?:purchase|transaction).*?(?:at\s+)?(.+?)\s+\$?([\d.,]+)', caseSensitive: false),
  ],
  incomePatterns: [
    RegExp(r'[Tt]ransfer\s+received.*?from\s+(.+?)\s+\$?([\d.,]+)', caseSensitive: false),
    RegExp(r'[Dd]irect\s+deposit.*?(.+?)\s+\$?([\d.,]+)', caseSensitive: false),
    RegExp(r'[Pp]ayroll.*?(?:deposit\s+)?(.+?)\s+\$?([\d.,]+)', caseSensitive: false),
    RegExp(r'[Dd]eposit\s+from\s+(.+?)\s+\$?([\d.,]+)', caseSensitive: false),
    RegExp(r'[Rr]efund.*?from\s+(.+?)\s+\$?([\d.,]+)', caseSensitive: false),
    RegExp(r'[Cc]redit\s+\$?([\d.,]+)\s+from\s+(.+)', caseSensitive: false),
  ],
  incomeSignals: [
    'transfer received', 'direct deposit', 'payroll deposit',
    'you received', 'you have received',
    'interest earned', 'interest paid',
    'received', 'deposit', 'refund', 'credit',
    'reimbursement', 'cashback', 'cash back',
    'payroll', 'salary', 'wages', 'dividend',
    'incoming',
  ],
  expenseSignals: [
    'card purchase', 'debit card', 'direct debit',
    'you sent', 'you paid', 'you transferred',
    'standing order', 'recurring payment',
    'purchase', 'payment', 'charge', 'debit',
    'withdrawal', 'sent', 'paid',
    'subscription', 'fee', 'penalty',
    'outgoing',
  ],
  stopWords: [
    'purchase', 'payment', 'charge', 'card', 'debit', 'credit',
    'at', 'to', 'from', 'for', 'the', 'a', 'an', 'of', 'in', 'on',
    'ref', 'reference', 'num', 'number', 'transaction',
    'eur', 'usd', 'gbp', 'dollars',
    'ltd', 'ltd.', 'llc', 'inc', 'inc.', 'co', 'co.',
    'plc', 'corp', 'corp.', 'limited', 'incorporated',
  ],
  noisePatterns: [
    RegExp(r'\$[\d.,]+'),
    RegExp(r'£[\d.,]+'),
    RegExp(r'[\d.,]+\s*(?:USD|GBP|EUR)', caseSensitive: false),
    RegExp(r'\d{2}[/-]\d{2}[/-]\d{2,4}'),
    RegExp(r'\d{6,}'),
    RegExp(r'\*+\d+'),
    RegExp(r'x{2,}\d+', caseSensitive: false),
    RegExp(r'\b\d{4}\b'),
    RegExp(r'\s{2,}'),
  ],
  genericTagKeywords: {
    'Vivienda (Alquiler/Hipoteca)': [
      'mortgage', 'rent', 'lease', 'housing', 'hoa',
      'homeowners association',
    ],
    'Comida (Supermercado)': [
      'grocery', 'groceries', 'supermarket', 'food store',
    ],
    'Ocio y Entretenimiento': [
      'cinema', 'theater', 'theatre', 'concert', 'tickets',
      'amusement park', 'bowling', 'arcade',
    ],
    'Restaurantes y Bares': [
      'restaurant', 'cafe', 'coffee shop', 'bar ', 'pizzeria',
      'pub ', 'grill', 'diner', 'eatery', 'takeaway', 'takeout',
    ],
    'Servicios del Hogar (Agua, Luz, Gas, Internet)': [
      'water bill', 'electric', 'electricity', 'gas bill',
      'internet', 'broadband', 'utility', 'utilities',
    ],
    'Transporte (Combustible, Mantenimiento Vehículo, Transporte Público)': [
      'fuel', 'gas station', 'petrol', 'diesel',
      'bus ', 'subway', 'metro ', 'train', 'rail',
      'parking', 'toll', 'garage', 'mechanic', 'mot ',
      'tire', 'tyre', 'taxi', 'cab ',
    ],
    'Salud (Médico, Farmacia, Seguro)': [
      'pharmacy', 'chemist', 'hospital', 'doctor', 'medical',
      'dental', 'dentist', 'optician', 'physiotherapy',
      'clinic', 'lab ', 'laboratory',
    ],
    'Educación (Cursos, Libros, Matrículas)': [
      'tuition', 'university', 'college', 'school fee',
      'enrollment', 'enrolment', 'student',
    ],
    'Ropa y Calzado': [
      'clothing', 'apparel', 'shoes', 'footwear', 'fashion',
    ],
    'Cuidado Personal (Peluquería, Cosméticos)': [
      'hairdresser', 'barber', 'beauty', 'cosmetics',
      'salon', 'nail ', 'spa ', 'waxing',
    ],
    'Mascotas': [
      'pet ', 'pets', 'veterinary', 'vet ', 'animal clinic',
      'pet food', 'pet store',
    ],
    'Viajes y Vacaciones': [
      'hotel', 'hostal', 'accommodation', 'flight', 'airline', 'airport',
    ],
    'Regalos y Celebraciones': [
      'gift', 'flowers', 'florist', 'celebration',
      'party', 'birthday', 'wedding',
    ],
    'Mobiliario y Decoración': [
      'furniture', 'mattress', 'sofa', 'decoration', 'home decor',
    ],
    'Reparaciones y Mejoras del Hogar': [
      'hardware store', 'plumber', 'electrician',
      'paint', 'renovation', 'locksmith', 'handyman',
    ],
    'Electrónica y Electrodomésticos': [
      'electronics', 'appliance', 'appliances',
    ],
    'Deudas y Préstamos': [
      'loan payment', 'loan repayment', 'amortization',
      'credit payment', 'financing', 'installment',
    ],
    'Impuestos y Tasas': [
      'tax ', 'taxes', 'irs', 'hmrc', 'council tax',
      'income tax', 'vat ', 'fine', 'penalty',
    ],
    'Seguros (no de salud ni vehículo)': [
      'home insurance', 'life insurance', 'renters insurance',
    ],
    'Deportes y Actividades Físicas': [
      'sport', 'tennis', 'swimming pool', 'climbing',
      'sports club', 'recreation',
    ],
    'Suscripciones (Streaming, Apps, Gimnasio)': [
      'gym', 'fitness',
    ],
    'Cultura (Libros, Revistas, Museos)': [
      'bookstore', 'bookshop', 'museum', 'exhibition',
      'newspaper', 'magazine',
    ],
    'Tecnología y Software': [
      'domain', 'hosting', 'server', 'cloud',
    ],
    'Ahorro e Inversión': [
      'investment fund', 'savings', 'deposit',
    ],
    'Desarrollo Profesional (Cursos, Talleres)': [
      'workshop', 'conference', 'seminar', 'professional development',
      'certification',
    ],
    'Hijos/Familiares (Gastos específicos)': [
      'daycare', 'nursery', 'childcare', 'school uniform',
      'summer camp', 'toy ',
    ],
    'Donaciones y Caridad': [
      'donation', 'charity', 'nonprofit', 'crowdfunding',
    ],
    'Salario y sueldo': [
      'salary', 'wages', 'payroll', 'pay check', 'paycheck',
      'direct deposit',
    ],
    'Otros ingresos': [
      'refund', 'reimbursement', 'benefit', 'subsidy',
      'pension', 'dividend', 'interest earned',
    ],
  },
);
