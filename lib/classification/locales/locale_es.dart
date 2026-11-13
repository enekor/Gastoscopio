import 'locale_config.dart';

final localeEs = LocaleConfig(
  localeCode: 'es',
  expensePatterns: [
    RegExp(r'[Cc]ompra.*?en\s+(.+?)\s+por\s+([\d.,]+)', caseSensitive: false),
    RegExp(r'[Pp]ago\s+(?:a|en)\s+(.+?)\s+por\s+([\d.,]+)', caseSensitive: false),
    RegExp(r'[Bb]izum\s+enviado.*?a\s+(.+?)\s+([\d.,]+)', caseSensitive: false),
    RegExp(r'[Rr]ecibo.*?\s+(.+?)\s+([\d.,]+)', caseSensitive: false),
    RegExp(r'[Cc]argo.*?\s+(.+?)\s+([\d.,]+)', caseSensitive: false),
    RegExp(r'[Aa]deudo.*?\s+(.+?)\s+([\d.,]+)', caseSensitive: false),
    RegExp(r'[Rr]etirada\s+(?:cajero|efectivo).*?([\d.,]+)', caseSensitive: false),
  ],
  incomePatterns: [
    RegExp(r'[Tt]ransferencia\s+recibida.*?de\s+(.+?)\s+([\d.,]+)', caseSensitive: false),
    RegExp(r'[Bb]izum\s+recibido.*?de\s+(.+?)\s+([\d.,]+)', caseSensitive: false),
    RegExp(r'[Ii]ngreso\s+(?:nómina|nomina).*?(.+?)\s+([\d.,]+)', caseSensitive: false),
    RegExp(r'[Aa]bono.*?\s+(.+?)\s+([\d.,]+)', caseSensitive: false),
  ],
  incomeSignals: [
    'transferencia recibida', 'bizum recibido',
    'te han enviado', 'te han transferido', 'has recibido',
    'intereses abonados', 'paga extra',
    'recibido', 'recibida', 'ingreso', 'abono',
    'devolucion', 'devolución', 'reembolso',
    'nomina', 'nómina', 'prestacion', 'prestación',
    'cobro', 'liquidacion', 'liquidación',
    'subsidio', 'pension', 'pensión', 'dividendo',
  ],
  expenseSignals: [
    'compra con tarjeta', 'pago con tarjeta',
    'transferencia enviada', 'bizum enviado',
    'has enviado', 'has pagado', 'has transferido',
    'compra', 'pago', 'cargo', 'adeudo',
    'retirada', 'enviado', 'enviada',
    'recibo', 'domiciliacion', 'domiciliación',
    'cuota', 'suscripcion', 'suscripción',
    'comision', 'comisión', 'penalizacion',
  ],
  stopWords: [
    'compra', 'pago', 'cargo', 'con', 'tarjeta', 'en',
    'por', 'de', 'del', 'la', 'el', 'los', 'las', 'su',
    'ref', 'referencia', 'num', 'numero', 'número',
    'operacion', 'operación', 'concepto',
    'eur', 'euros', 'euro', 'usd',
    's.l', 's.l.', 's.a', 's.a.', 'sl', 'sa', 'slu', 's.l.u',
    'sociedad', 'limitada', 'anonima',
  ],
  noisePatterns: [
    RegExp(r'[\d.,]+\s*€'),
    RegExp(r'[\d.,]+\s*EUR', caseSensitive: false),
    RegExp(r'\d{2}[/-]\d{2}[/-]\d{2,4}'),
    RegExp(r'\d{6,}'),
    RegExp(r'\*+\d+'),
    RegExp(r'\b[A-Z]{2}\d{2}[A-Z0-9]{4,}\b'),
    RegExp(r'\b\d{4}\b'),
    RegExp(r'\s{2,}'),
  ],
  genericTagKeywords: {
    'Vivienda (Alquiler/Hipoteca)': [
      'hipoteca', 'alquiler', 'renta mensual', 'cuota vivienda',
      'comunidad propietarios', 'comunidad de vecinos',
    ],
    'Comida (Supermercado)': [
      'supermercado', 'alimentacion', 'comestibles',
    ],
    'Ocio y Entretenimiento': [
      'cine', 'teatro', 'concierto', 'entradas', 'parque atracciones',
      'escape room', 'bolera', 'karaoke',
    ],
    'Restaurantes y Bares': [
      'restaurante', 'rest.', 'cafeteria', 'bar ', 'pizzeria',
      'kebab', 'wok', 'sushi', 'cerveceria',
    ],
    'Servicios del Hogar (Agua, Luz, Gas, Internet)': [
      'agua ', 'aguas de', 'gas natural', 'electricidad',
      'telecomunicaciones', 'fibra', 'adsl',
    ],
    'Transporte (Combustible, Mantenimiento Vehículo, Transporte Público)': [
      'gasolina', 'gasolinera', 'combustible', 'autobus', 'metro ',
      'parking', 'peaje', 'autopista', 'telepeaje', 'via-t',
      'taller ', 'mecanico', 'itv', 'neumaticos', 'taxi',
    ],
    'Salud (Médico, Farmacia, Seguro)': [
      'farmacia', 'clinic', 'hospital', 'medico', 'dental', 'dentista',
      'optica', 'fisioterapia', 'fisio', 'laboratorio',
    ],
    'Educación (Cursos, Books, Matrículas)': [
      'matricula', 'universidad', 'colegio', 'academia', 'autoescuela',
      'tasas academicas',
    ],
    'Ropa y Calzado': [
      'zapateria', 'calzado', 'ropa', 'textil', 'modas',
    ],
    'Cuidado Personal (Peluquería, Cosméticos)': [
      'peluqueria', 'barberia', 'estetica', 'perfumeria',
      'manicura', 'pedicura', 'spa ', 'depilacion',
    ],
    'Mascotas': [
      'mascota', 'veterinari', 'clinica veterinaria', 'pienso',
    ],
    'Viajes y Vacaciones': [
      'hotel', 'hostal', 'hostel', 'alojamiento', 'aeropuerto',
    ],
    'Regalos y Celebraciones': [
      'regalo', 'florister', 'flores', 'celebracion',
      'fiesta', 'cumpleanos', 'boda', 'bautizo',
    ],
    'Mobiliario y Decoración': [
      'mueble', 'colchon', 'sofa', 'decoracion',
    ],
    'Reparaciones y Mejoras del Hogar': [
      'ferreteria', 'fontanero', 'electricista',
      'pintura', 'reforma', 'cerrajero', 'cristalero',
    ],
    'Electrónica y Electrodomésticos': [
      'electrodomestico', 'lavadora', 'frigorifico',
    ],
    'Deudas y Préstamos': [
      'cuota prestamo', 'amortizacion', 'credito',
      'prestamo personal', 'financiacion',
    ],
    'Impuestos y Tasas': [
      'agencia tributaria', 'aeat', 'hacienda',
      'ibi', 'irpf', 'impuesto', 'ayuntamiento', 'tasa', 'multa', 'dgt',
    ],
    'Seguros (no de salud ni vehículo)': [
      'seguro hogar', 'seguro vida', 'seguro decesos',
    ],
    'Deportes y Actividades Físicas': [
      'padel', 'tenis', 'piscina', 'escalada',
      'club deportivo', 'polideportivo',
    ],
    'Suscripciones (Streaming, Apps, Gimnasio)': [
      'gimnasio', 'gym',
    ],
    'Cultura (Libros, Revistas, Museos)': [
      'libreria', 'museo', 'exposicion', 'prensa', 'periodico', 'revista',
    ],
    'Tecnología y Software': [
      'dominio', 'hosting',
    ],
    'Ahorro e Inversión': [
      'fondo inversion', 'deposito', 'objetivo ahorro',
    ],
    'Desarrollo Profesional (Cursos, Talleres)': [
      'taller', 'workshop', 'conferencia', 'congreso',
      'formacion profesional', 'certificacion',
    ],
    'Hijos/Familiares (Gastos específicos)': [
      'guarderia', 'uniforme escolar', 'ludoteca', 'campamento', 'juguete',
    ],
    'Donaciones y Caridad': [
      'donacion', 'ong', 'crowdfunding',
    ],
    'Salario y sueldo': [
      'nomina', 'nómina', 'salario', 'sueldo', 'paga extra',
    ],
    'Otros ingresos': [
      'devolucion', 'reembolso', 'prestacion', 'subsidio',
      'pension', 'dividendo', 'intereses',
    ],
  },
);
