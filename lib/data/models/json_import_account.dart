class Account {
  String? id;
  String? nombre;
  List<Meses>? meses;
  int? posicion;
  List<Gastos>? fijos;
  List<Gastos>? deudas;
  String? color;
  List<String>? tags;
  List<Presupuestos>? presupuestos;

  Account({
    this.id,
    this.nombre,
    this.meses,
    this.posicion,
    this.fijos,
    this.deudas,
    this.color,
    this.tags,
    this.presupuestos,
  });

  Account.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nombre = json['Nombre'];
    if (json['Meses'] != null) {
      meses = <Meses>[];
      json['Meses'].forEach((v) {
        meses!.add(new Meses.fromJson(v));
      });
    }
    posicion = json['posicion'];
    if (json['fijos'] != null) {
      fijos = <Gastos>[];
      json['fijos'].forEach((v) {
        fijos!.add(new Gastos.fromJson(v));
      });
    }
    if (json['deudas'] != null) {
      deudas = <Gastos>[];
      json['deudas'].forEach((v) {
        deudas!.add(new Gastos.fromJson(v));
      });
    }
    color = json['color'];
    tags = json['tags'].cast<String>();
    if (json['presupuestos'] != null) {
      presupuestos = <Presupuestos>[];
      json['presupuestos'].forEach((v) {
        presupuestos!.add(new Presupuestos.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['Nombre'] = this.nombre;
    if (this.meses != null) {
      data['Meses'] = this.meses!.map((v) => v.toJson()).toList();
    }
    data['posicion'] = this.posicion;
    if (this.fijos != null) {
      data['fijos'] = this.fijos!.map((v) => v.toJson()).toList();
    }
    if (this.deudas != null) {
      data['deudas'] = this.deudas!.map((v) => v.toJson()).toList();
    }
    data['color'] = this.color;
    data['tags'] = this.tags;
    if (this.presupuestos != null) {
      data['presupuestos'] = this.presupuestos!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Meses {
  List<Gastos>? gastos;
  double? ingreso;
  List<Gastos>? extras;
  String? nMes;
  int? anno;

  Meses({this.gastos, this.ingreso, this.extras, this.nMes, this.anno});

  Meses.fromJson(Map<String, dynamic> json) {
    if (json['Gastos'] != null) {
      gastos = <Gastos>[];
      json['Gastos'].forEach((v) {
        gastos!.add(new Gastos.fromJson(v));
      });
    }
    ingreso = json['Ingreso'];
    if (json['Extras'] != null) {
      extras = <Gastos>[];
      json['Extras'].forEach((v) {
        extras!.add(new Gastos.fromJson(v));
      });
    }
    nMes = json['NMes'];
    anno = json['Anno'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.gastos != null) {
      data['Gastos'] = this.gastos!.map((v) => v.toJson()).toList();
    }
    data['Ingreso'] = this.ingreso;
    if (this.extras != null) {
      data['Extras'] = this.extras!.map((v) => v.toJson()).toList();
    }
    data['NMes'] = this.nMes;
    data['Anno'] = this.anno;
    return data;
  }
}

class Gastos {
  String? nombre;
  double? valor;
  int? anno;
  int? mes;
  int? dia;
  String? tag;

  Gastos({this.nombre, this.valor, this.anno, this.mes, this.dia, this.tag});

  Gastos.fromJson(Map<String, dynamic> json) {
    nombre = json['nombre'];
    valor = json['valor'];
    anno = json['anno'];
    mes = json['mes'];
    dia = json['dia'];
    tag = json['tag'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['nombre'] = this.nombre;
    data['valor'] = this.valor;
    data['anno'] = this.anno;
    data['mes'] = this.mes;
    data['dia'] = this.dia;
    data['tag'] = this.tag;
    return data;
  }
}

class Presupuestos {
  String? description;
  double? percentage;
  double? amount;
  List<String>? tags;

  Presupuestos({this.description, this.percentage, this.amount, this.tags});

  Presupuestos.fromJson(Map<String, dynamic> json) {
    description = json['description'];
    percentage = json['percentage'];
    amount = json['amount'];
    if (json['tags'] != null) {
      tags = <String>[];
      json['tags'].forEach((v) {
        tags!.add(v);
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['description'] = this.description;
    data['percentage'] = this.percentage;
    data['amount'] = this.amount;
    if (this.tags != null) {
      data['tags'] = this.tags!.map((v) => v).toList();
    }
    return data;
  }
}
