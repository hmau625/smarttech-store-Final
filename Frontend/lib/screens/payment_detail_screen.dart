import 'package:smarttech_store/config/api_config.dart';
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
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {

  final nombre         = TextEditingController();
  final apellido       = TextEditingController();
  final documento      = TextEditingController();
  final telefono       = TextEditingController();
  final direccion      = TextEditingController();
  final tarjeta        = TextEditingController();
  final cvv            = TextEditingController();
  final numeroNequi    = TextEditingController();
  final referenciaPago = TextEditingController();
  final countryController = TextEditingController();
  final stateController   = TextEditingController();
  final cityController    = TextEditingController();

  DateTime? fecha;
  bool loading           = false;
  bool aceptaCondiciones = false;
  String? tipoDocumento;

  final baseUrl = ApiConfig.baseUrl;

  // â”€â”€ Paleta de colores â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const _bg      = Color(0xFF060D17);
  static const _surface = Color(0xFF0D1F33);
  static const _card    = Color(0xFF111E2E);
  static const _accent  = Color(0xFF00D4FF);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);

  List<String> get tiposDocumento {
    if (countryController.text.trim() == "Colombia") return ["CC", "TI", "CE"];
    if (countryController.text.trim().isEmpty) return [];
    return ["PAS"];
  }

  @override
  void initState() {
    super.initState();
    countryController.addListener(() => setState(() => tipoDocumento = null));
  }

  @override
  void dispose() {
    for (final c in [nombre, apellido, documento, telefono, direccion,
                     tarjeta, cvv, numeroNequi, referenciaPago,
                     countryController, stateController, cityController]) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmtPrice(double v) {
    final parts   = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '\$$intPart.${parts[1]}';
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  void msg(String t, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline : Icons.check_circle_outline,
            color: error ? Colors.redAccent : const Color(0xFF4CAF50), size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(t, style: const TextStyle(color: _textPri, fontSize: 13))),
      ]),
      backgroundColor: _surface,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: (error ? Colors.redAccent : const Color(0xFF4CAF50)).withOpacity(0.35)),
      ),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> pickDate() async {
    final min = DateTime.now().add(const Duration(days: 7));
    final d = await showDatePicker(
      context: context,
      firstDate: min,
      lastDate: DateTime(2030),
      initialDate: min,
      builder: (_, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _accent, onPrimary: Colors.black,
            surface: _card, onSurface: _textPri,
          ),
          dialogBackgroundColor: _surface,
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => fecha = d);
  }

  void formatCard(String value) {
    String n = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (n.length > 16) n = n.substring(0, 16);
    String out = "";
    for (int i = 0; i < n.length; i++) {
      if (i % 4 == 0 && i != 0) out += "-";
      out += n[i];
    }
    tarjeta.value = TextEditingValue(
      text: out, selection: TextSelection.collapsed(offset: out.length));
  }

  Future<void> pagar() async {
    final isCard  = widget.method == "tarjeta";
    final isNequi = widget.method == "nequi";
    final isCOD   = widget.method == "contra_entrega";

    if (nombre.text.trim().length < 3)   return msg("Nombre invÃ¡lido (mÃ­n. 3 letras)", error: true);
    if (apellido.text.trim().length < 3)  return msg("Apellido invÃ¡lido (mÃ­n. 3 letras)", error: true);
    if (tipoDocumento == null)            return msg("Selecciona el tipo de documento", error: true);
    if (documento.text.trim().length < 6) return msg("Documento invÃ¡lido (mÃ­n. 6 dÃ­gitos)", error: true);
    if (!RegExp(r'^[0-9]+$').hasMatch(documento.text.trim()))
      return msg("El documento solo debe tener nÃºmeros", error: true);
    if (!RegExp(r'^[0-9]{10}$').hasMatch(telefono.text.trim()))
      return msg("TelÃ©fono invÃ¡lido (10 dÃ­gitos)", error: true);
    if (countryController.text.trim().isEmpty) return msg("Selecciona el paÃ­s", error: true);
    if (cityController.text.trim().isEmpty)    return msg("Selecciona la ciudad", error: true);
    if (direccion.text.trim().length < 5)      return msg("DirecciÃ³n invÃ¡lida", error: true);
    if (fecha == null)                         return msg("Selecciona fecha de entrega", error: true);

    if (isCard) {
      final card = tarjeta.text.replaceAll("-", "");
      if (card.length != 16) return msg("NÃºmero de tarjeta invÃ¡lido", error: true);
      if (cvv.text.length != 3) return msg("CVV invÃ¡lido (3 dÃ­gitos)", error: true);
      final ref = referenciaPago.text.trim();
      if (ref.length < 3 || ref.length > 6 || !RegExp(r'^[0-9]+$').hasMatch(ref))
        return msg("CÃ³digo de confirmaciÃ³n invÃ¡lido (3 a 6 dÃ­gitos)", error: true);
    }

    if (isNequi) {
      if (!RegExp(r'^[0-9]{10}$').hasMatch(numeroNequi.text.trim()))
        return msg("NÃºmero Nequi invÃ¡lido (10 dÃ­gitos)", error: true);
      final ref = referenciaPago.text.trim();
      if (ref.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(ref))
        return msg("CÃ³digo Nequi invÃ¡lido (exactamente 4 dÃ­gitos)", error: true);
    }

    if (isCOD && !aceptaCondiciones)
      return msg("Debes aceptar las condiciones", error: true);

    setState(() => loading = true);

    try {
      final token = await getToken();
      final res = await http.post(
        Uri.parse("$baseUrl/checkout/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "token":            token,
          "metodo_pago":      widget.method,
          "nombre":           nombre.text.trim(),
          "apellido":         apellido.text.trim(),
          "tipo_documento":   tipoDocumento,
          "documento":        documento.text.trim(),
          "pais":             countryController.text.trim(),
          "departamento":     stateController.text.trim(),
          "ciudad":           cityController.text.trim(),
          "direccion":        direccion.text.trim(),
          "fecha_entrega":    fecha.toString(),
          "numero_contacto":  telefono.text.trim(),
          "numero_nequi":     numeroNequi.text.trim(),
          "tarjeta":          tarjeta.text.replaceAll("-", ""),
          "cvv":              cvv.text.trim(),
          "referencia_pago":  referenciaPago.text.trim(),
        }),
      );

      setState(() => loading = false);

      if (res.statusCode == 200 || res.statusCode == 201) {
        msg("Â¡Compra realizada con Ã©xito!");
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SuccessScreen(token: widget.token),
        ));
      } else {
        try {
          final data = jsonDecode(res.body);
          msg(data["detail"] ?? "Error en el checkout", error: true);
        } catch (_) {
          msg("Error en el checkout", error: true);
        }
      }
    } catch (e) {
      setState(() => loading = false);
      msg("Error de conexiÃ³n", error: true);
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• WIDGETS â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _input(String label, TextEditingController c, IconData icon, {
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatters,
    Function(String)? onChanged,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c, keyboardType: type,
        inputFormatters: formatters, onChanged: onChanged, maxLines: maxLines,
        style: const TextStyle(color: _textPri, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          prefixIcon: Icon(icon, color: _accent, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: _textSec, fontSize: 13),
          filled: true, fillColor: const Color(0xFF162638),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.4)),
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _divider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.20), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: _accent, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(
                color: _textPri, fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  // â”€â”€ Location Picker con texto completamente blanco en el diÃ¡logo â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _locationPicker() {
    return Theme(
      data: ThemeData.dark().copyWith(
        // Texto general en todo el widget y diÃ¡logos
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: _textPri,
          displayColor: _textPri,
        ),
        // Estilo de los ListTile dentro del diÃ¡logo (cada paÃ­s/estado/ciudad)
        listTileTheme: const ListTileThemeData(
          textColor: Color(0xFFEFF6FF),
          titleTextStyle: TextStyle(
            color: Color(0xFFEFF6FF),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          iconColor: Color(0xFF00D4FF),
        ),
        // Tema del diÃ¡logo â€” fuerza texto blanco en tÃ­tulo y contenido
        dialogTheme: DialogThemeData(
          backgroundColor: _card,
          titleTextStyle: const TextStyle(
            color: _textPri,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: const TextStyle(
            color: Color(0xFFEFF6FF),
            fontSize: 15,
          ),
        ),
        dialogBackgroundColor: _card,
        primaryColor: _accent,
        // Barra de bÃºsqueda dentro del diÃ¡logo
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0A1929),
          hintStyle: TextStyle(color: _textSec.withOpacity(0.6), fontSize: 13),
          prefixIconColor: _textSec,
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: _accent.withOpacity(0.40))),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: _accent, width: 1.5)),
        ),
        // ColorScheme completo: onSurface y onBackground son los que
        // Flutter usa para pintar el texto sobre fondos oscuros
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          onPrimary: Colors.black,
          surface: _card,
          onSurface: Color(0xFFEFF6FF),       // â† texto sobre superficie (lista)
          secondary: _accent,
          onSecondary: Colors.black,
          background: _card,
          onBackground: Color(0xFFEFF6FF),    // â† texto sobre fondo del diÃ¡logo
        ),
        // BotÃ³n "Close" del diÃ¡logo
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _accent),
        ),
      ),
      child: CountryStateCityPicker(
        country: countryController,
        state: stateController,
        city: cityController,
        dialogColor: _card,
        textFieldDecoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF162638),
          labelStyle: const TextStyle(color: _textSec, fontSize: 13),
          suffixIcon: const Icon(Icons.arrow_drop_down, color: _accent),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.4)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCard  = widget.method == "tarjeta";
    final isNequi = widget.method == "nequi";
    final isCOD   = widget.method == "contra_entrega";
    final paisSeleccionado = countryController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _surface,
        leading: const BackButton(color: _accent),
        centerTitle: true,
        title: Text(
          isCard ? "Pago con tarjeta" : isNequi ? "Pago con Nequi" : "Contra entrega",
          style: const TextStyle(color: _textPri, fontWeight: FontWeight.w800, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // â”€â”€ Total â”€â”€
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accent.withOpacity(0.30)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.receipt_outlined, color: _accent, size: 22),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Total a pagar", style: TextStyle(color: _textSec, fontSize: 12)),
                  Text(_fmtPrice(widget.total),
                      style: const TextStyle(color: _accent, fontSize: 26, fontWeight: FontWeight.w800)),
                ]),
              ]),
            ),

            // â”€â”€ Datos personales â”€â”€
            _section("Datos personales", Icons.person_outline, Column(
              children: [
                _input("Nombre", nombre, Icons.person_outline),
                _input("Apellido", apellido, Icons.person),
                _input("TelÃ©fono de contacto", telefono, Icons.phone_outlined,
                    type: TextInputType.phone,
                    formatters: [FilteringTextInputFormatter.digitsOnly,
                                 LengthLimitingTextInputFormatter(10)]),
              ],
            )),

            // â”€â”€ DirecciÃ³n â”€â”€
            _section("DirecciÃ³n de entrega", Icons.location_on_outlined, Column(
              children: [
                _locationPicker(),
                const SizedBox(height: 14),

                // Documento â€” aparece solo cuando hay paÃ­s seleccionado
                if (!paisSeleccionado)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accent.withOpacity(0.20)),
                    ),
                    child: Row(children: const [
                      Icon(Icons.info_outline, color: _textSec, size: 15),
                      SizedBox(width: 8),
                      Text("Selecciona el paÃ­s para ver los tipos de documento",
                          style: TextStyle(color: _textSec, fontSize: 12)),
                    ]),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: DropdownButtonFormField<String>(
                      value: tipoDocumento,
                      dropdownColor: _card,
                      iconEnabledColor: _accent,
                      style: const TextStyle(color: _textPri, fontSize: 14),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        labelText: "Tipo de documento",
                        prefixIcon: const Icon(Icons.badge_outlined, color: _accent, size: 20),
                        labelStyle: const TextStyle(color: _textSec, fontSize: 13),
                        filled: true, fillColor: const Color(0xFF162638),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _accent, width: 1.4)),
                      ),
                      items: tiposDocumento.map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: const TextStyle(color: _textPri)),
                      )).toList(),
                      onChanged: (v) => setState(() => tipoDocumento = v),
                    ),
                  ),
                  _input("NÃºmero de documento", documento, Icons.badge_outlined,
                      type: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly,
                                   LengthLimitingTextInputFormatter(12)]),
                ],

                _input("DirecciÃ³n exacta", direccion, Icons.home_outlined, maxLines: 2),

                // â”€â”€ Fecha de entrega â”€â”€
                GestureDetector(
                  onTap: pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162638),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: fecha != null ? _accent.withOpacity(0.50) : Colors.white.withOpacity(0.05))),
                    child: Row(children: [
                      Icon(Icons.calendar_today_outlined,
                          color: fecha != null ? _accent : _textSec, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        fecha != null
                            ? "Entrega: ${fecha!.day}/${fecha!.month}/${fecha!.year}"
                            : "Seleccionar fecha de entrega",
                        style: TextStyle(
                          color: fecha != null ? _textPri : _textSec, fontSize: 14,
                          fontWeight: fecha != null ? FontWeight.w600 : FontWeight.normal)),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          color: fecha != null ? _accent : _textSec, size: 18),
                    ]),
                  ),
                ),
              ],
            )),

            // â”€â”€ Tarjeta â”€â”€
            if (isCard)
              _section("Datos de tarjeta", Icons.credit_card_outlined, Column(children: [
                _input("NÃºmero de tarjeta", tarjeta, Icons.credit_card,
                    type: TextInputType.number, onChanged: formatCard),
                _input("CVV (3 dÃ­gitos)", cvv, Icons.lock_outline,
                    type: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly,
                                 LengthLimitingTextInputFormatter(3)]),
                _input("CÃ³digo de confirmaciÃ³n (3â€“6 dÃ­gitos)", referenciaPago,
                    Icons.pin_outlined,
                    type: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly,
                                 LengthLimitingTextInputFormatter(6)]),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.05), borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accent.withOpacity(0.20))),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: _textSec, size: 14),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                      "El cÃ³digo de confirmaciÃ³n es enviado por tu banco al aprobar el pago",
                      style: TextStyle(color: _textSec, fontSize: 11))),
                  ]),
                ),
              ])),

            // â”€â”€ Nequi â”€â”€
            if (isNequi)
              _section("Datos Nequi", Icons.phone_android_outlined, Column(children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C2DC7).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF6C2DC7).withOpacity(0.30))),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: Color(0xFF9B59B6), size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                      "Ingresa tu nÃºmero Nequi y el cÃ³digo de 4 dÃ­gitos que te llegarÃ¡",
                      style: TextStyle(color: Color(0xFF9B59B6), fontSize: 12))),
                  ]),
                ),
                _input("NÃºmero Nequi (10 dÃ­gitos)", numeroNequi, Icons.phone_android,
                    type: TextInputType.phone,
                    formatters: [FilteringTextInputFormatter.digitsOnly,
                                 LengthLimitingTextInputFormatter(10)]),
                _input("CÃ³digo de confirmaciÃ³n (4 dÃ­gitos)", referenciaPago,
                    Icons.pin_outlined,
                    type: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly,
                                 LengthLimitingTextInputFormatter(4)]),
              ])),

            // â”€â”€ Contra entrega â”€â”€
            if (isCOD)
              _section("Contra entrega", Icons.local_shipping_outlined, Column(children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCA28).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCA28).withOpacity(0.30))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Text("Condiciones:", style: TextStyle(color: Color(0xFFFFCA28), fontWeight: FontWeight.w700, fontSize: 13)),
                    SizedBox(height: 8),
                    Text("â€¢ Pago en efectivo al recibir el producto",      style: TextStyle(color: _textSec, fontSize: 12, height: 1.5)),
                    Text("â€¢ Debes estar presente al momento de la entrega", style: TextStyle(color: _textSec, fontSize: 12, height: 1.5)),
                    Text("â€¢ El transportador esperarÃ¡ mÃ¡ximo 10 minutos",   style: TextStyle(color: _textSec, fontSize: 12, height: 1.5)),
                    Text("â€¢ Ten el dinero exacto disponible",               style: TextStyle(color: _textSec, fontSize: 12, height: 1.5)),
                  ]),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => setState(() => aceptaCondiciones = !aceptaCondiciones),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: aceptaCondiciones ? _accent.withOpacity(0.20) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: aceptaCondiciones ? _accent : _textSec, width: 1.5)),
                      child: aceptaCondiciones
                          ? const Icon(Icons.check_rounded, color: _accent, size: 14) : null,
                    ),
                    const SizedBox(width: 10),
                    const Text("Acepto las condiciones de contra entrega",
                        style: TextStyle(color: _textPri, fontSize: 13)),
                  ]),
                ),
              ])),

            const SizedBox(height: 8),

            // â”€â”€ BotÃ³n pagar â”€â”€
            GestureDetector(
              onTap: loading ? null : pagar,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  color: loading ? _accent.withOpacity(0.50) : _accent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: loading ? [] : [BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 18)],
                ),
                child: loading
                    ? const Center(child: SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.lock_outline_rounded, color: Colors.black, size: 18),
                        const SizedBox(width: 8),
                        Text("Pagar ${_fmtPrice(widget.total)}",
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16)),
                      ]),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}