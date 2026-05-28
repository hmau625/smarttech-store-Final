import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_state_city_pro/country_state_city_pro.dart';
import 'success_screen.dart';

class PaymentDetailScreen extends StatefulWidget {
  final String method;
  final double total;
  final String token;

  const PaymentDetailScreen({
    super.key,
    required this.method,
    required this.total,
    required this.token,
  });

  @override
  State<PaymentDetailScreen> createState() =>
      _PaymentDetailScreenState();
}

class _PaymentDetailScreenState
    extends State<PaymentDetailScreen> {

  // 🔹 CONTROLLERS
  final nombre = TextEditingController();
  final apellido = TextEditingController();
  final documento = TextEditingController();
  final telefono = TextEditingController();
  final direccion = TextEditingController();
  final tarjeta = TextEditingController();
  final cvv = TextEditingController();
  final otp = TextEditingController();
  final numeroNequi = TextEditingController();

  final countryController = TextEditingController();
  final stateController = TextEditingController();
  final cityController = TextEditingController();

  // 🔹 VARIABLES
  DateTime? fecha;
  bool loading = false;
  bool aceptaCondiciones = false;

  String? tipoDocumento;
  String? countryValue;
  String? stateValue;
  String? cityValue;

  List<String> tiposDocumento = [];

  final baseUrl = "http://127.0.0.1:8000";

  // 🎨 UI
  static const _bg = Color(0xFF060D17);
  static const _card = Color(0xFF111E2E);
  static const _accent = Color(0xFF00D4FF);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);

  @override
  void initState() {
    super.initState();

    countryController.addListener(() {
      actualizarDocumentos();
    });
  }

  // 🔹 DOCUMENTOS
  void actualizarDocumentos() {
    if (countryController.text == "Colombia") {
      tiposDocumento = ["CC", "TI", "CE"];
    } else {
      tiposDocumento = ["PAS"];
    }

    setState(() {
      tipoDocumento = null;
    });
  }

  // 🔹 TOKEN
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // 🔹 MENSAJES
  void msg(String t, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t),
        backgroundColor:
            error ? Colors.red : Colors.green,
      ),
    );
  }

  // 🔹 FECHA
  Future<void> pickDate() async {
    final min =
        DateTime.now().add(const Duration(days: 7));

    final d = await showDatePicker(
      context: context,
      firstDate: min,
      lastDate: DateTime(2030),
      initialDate: min,
    );

    if (d != null) setState(() => fecha = d);
  }

  // 🔹 TARJETA FORMATO
  void formatCard(String v) {
    String n =
        v.replaceAll(RegExp(r'[^0-9]'), '');

    if (n.length > 16) {
      n = n.substring(0, 16);
    }

    String out = "";

    for (int i = 0; i < n.length; i++) {
      if (i % 4 == 0 && i != 0) out += "-";
      out += n[i];
    }

    tarjeta.value = TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(
        offset: out.length,
      ),
    );
  }

  // 🔥 PAGO
  Future<void> pagar() async {

    countryValue = countryController.text;
    stateValue = stateController.text;
    cityValue = cityController.text;

    String telefonoVal = telefono.text.trim();

    // VALIDACIONES
    if (tipoDocumento == null) {
      return msg(
        "Selecciona documento",
        error: true,
      );
    }

    if (!RegExp(r'^[0-9]{10}$')
        .hasMatch(telefonoVal)) {
      return msg(
        "Teléfono inválido",
        error: true,
      );
    }

    setState(() => loading = true);

    final token = await getToken();

    final res = await http.post(
      Uri.parse("$baseUrl/checkout/"),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "token": token,
        "metodo_pago": widget.method,
        "nombre": nombre.text,
        "apellido": apellido.text,
        "tipo_documento": tipoDocumento,
        "documento": documento.text,
        "pais": countryValue,
        "departamento": stateValue,
        "ciudad": cityValue,
        "direccion": direccion.text,
        "fecha_entrega": fecha.toString(),
        "referencia_pago": otp.text,
        "numero_contacto": telefonoVal
      }),
    );

    setState(() => loading = false);

    if (res.statusCode == 200) {
      Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => SuccessScreen(
      token: widget.token,
    ),
  ),
);
    } else {
      msg(res.body, error: true);
    }
  }

  // 🔹 INPUT UI
  Widget input(
    String label,
    TextEditingController c,
    IconData icon, {
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatters,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: c,
        keyboardType: type,
        inputFormatters: formatters,
        onChanged: onChanged,
        style: const TextStyle(
          color: _textPri,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
          prefixIcon: Icon(
            icon,
            color: _accent,
            size: 22,
          ),
          labelText: label,
          labelStyle: const TextStyle(
            color: _textSec,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: const Color(0xFF162638),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(18),
            borderSide: BorderSide(
              color:
                  Colors.white.withOpacity(0.05),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: _accent,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 SECTION UI
  Widget section(String title, Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: const TextStyle(
              color: _accent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 20),

          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: _bg,
        centerTitle: true,
        iconTheme:
            const IconThemeData(color: Colors.white),
        title: Text(
          "Pago ${widget.method}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // 👤 DATOS
            section(
              "Información personal",

              Column(
                children: [

                  input(
                    "Nombre",
                    nombre,
                    Icons.person,
                  ),

                  input(
                    "Apellido",
                    apellido,
                    Icons.person_outline,
                  ),

                  DropdownButtonFormField<String>(
                    value: tipoDocumento,
                    dropdownColor: _card,
                    iconEnabledColor: _accent,

                    style: const TextStyle(
                      color: _textPri,
                    ),

                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),

                      labelText:
                          "Tipo de documento",

                      labelStyle:
                          const TextStyle(
                        color: _textSec,
                        fontWeight:
                            FontWeight.w500,
                      ),

                      filled: true,

                      fillColor:
                          const Color(0xFF162638),

                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                                18),
                        borderSide: BorderSide(
                          color: Colors.white
                              .withOpacity(0.05),
                        ),
                      ),

                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                                18),
                        borderSide:
                            const BorderSide(
                          color: _accent,
                          width: 1.4,
                        ),
                      ),
                    ),

                    items: tiposDocumento
                        .map(
                          (doc) =>
                              DropdownMenuItem(
                            value: doc,
                            child: Text(
                              doc,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(),

                    onChanged: (v) =>
                        setState(
                      () =>
                          tipoDocumento = v,
                    ),
                  ),

                  const SizedBox(height: 18),

                  input(
                    "Número documento",
                    documento,
                    Icons.badge,
                    type:
                        TextInputType.number,
                  ),

                  input(
                    "Teléfono",
                    telefono,
                    Icons.phone,
                    type:
                        TextInputType.phone,
                    formatters: [
                      FilteringTextInputFormatter
                          .digitsOnly,
                      LengthLimitingTextInputFormatter(
                          10),
                    ],
                  ),
                ],
              ),
            ),

            // 🌍 UBICACIÓN
section(
  "Dirección de entrega",

  Column(
    children: [

      Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color(0xFF162638),

          hintColor: _textSec,

          textTheme: const TextTheme(

            bodyLarge: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),

            bodyMedium: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          inputDecorationTheme: InputDecorationTheme(
            labelStyle: const TextStyle(
              color: _textSec,
            ),

            filled: true,
            fillColor: const Color(0xFF162638),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.05),
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: _accent,
                width: 1.4,
              ),
            ),
          ),
        ),

        child: Container(
          width: double.infinity,

          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),

          margin: const EdgeInsets.only(bottom: 18),

          decoration: BoxDecoration(
            color: const Color(0xFF162638),

            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: Colors.white.withOpacity(0.05),
            ),
          ),

          child: Theme(
            data: Theme.of(context).copyWith(

              textTheme: const TextTheme(

                bodyLarge: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),

                bodyMedium: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),

              hintColor: _textSec,
            ),

            child: CountryStateCityPicker(
              country: countryController,
              state: stateController,
              city: cityController,
            ),
          ),
        ),
      ),

      const SizedBox(height: 18),

      input(
        "Dirección",
        direccion,
        Icons.home,
      ),

      SizedBox(
        width: double.infinity,

        child: ElevatedButton.icon(
          onPressed: pickDate,

          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.black,

            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          icon: const Icon(Icons.calendar_month),

          label: Text(
            fecha == null
                ? "Seleccionar fecha"
                : fecha.toString().split(" ")[0],

            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  ),
),
            // 💳 PAGO
            section(
              "Método de pago",

              Column(
                children: [

                  if (widget.method ==
                      "tarjeta")
                    input(
                      "XXXX-XXXX-XXXX-XXXX",
                      tarjeta,
                      Icons.credit_card,
                      type:
                          TextInputType.number,
                      onChanged: formatCard,
                    ),

                  if (widget.method ==
                      "tarjeta")
                    input(
                      "CVV",
                      cvv,
                      Icons.lock,
                      type:
                          TextInputType.number,
                      formatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                        LengthLimitingTextInputFormatter(
                            3),
                      ],
                    ),

                  if (widget.method ==
                      "nequi")
                    input(
                      "Número Nequi",
                      numeroNequi,
                      Icons.phone_android,
                      type:
                          TextInputType.phone,
                    ),

                  input(
                    "OTP",
                    otp,
                    Icons.lock_outline,
                    type:
                        TextInputType.number,
                    formatters: [
                      FilteringTextInputFormatter
                          .digitsOnly,
                      LengthLimitingTextInputFormatter(
                          6),
                    ],
                  ),

                  if (widget.method ==
                      "contra_entrega")
                    Theme(
                      data: Theme.of(context)
                          .copyWith(
                        unselectedWidgetColor:
                            Colors.white,
                      ),
                      child: CheckboxListTile(
                        value:
                            aceptaCondiciones,

                        activeColor: _accent,

                        onChanged: (v) =>
                            setState(
                          () =>
                              aceptaCondiciones =
                                  v!,
                        ),

                        title: const Text(
                          "Aceptar condiciones",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),

                        controlAffinity:
                            ListTileControlAffinity
                                .leading,
                      ),
                    ),
                ],
              ),
            ),

            // 💰 TOTAL
            section(
              "Resumen",

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [

                  const Text(
                    "Total",
                    style: TextStyle(
                      color: _textSec,
                      fontSize: 16,
                    ),
                  ),

                  Text(
                    "\$${widget.total}",
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 🔥 BOTÓN
            SizedBox(
              width: double.infinity,
              height: 58,

              child: ElevatedButton(
                onPressed:
                    loading ? null : pagar,

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  elevation: 8,
                  shadowColor:
                      _accent.withOpacity(0.4),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                            18),
                  ),
                ),

                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.black,
                      )
                    : const Text(
                        "Confirmar pedido",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}