import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# CONFIGURA TU GMAIL AQUÃ
# 1. Ve a https://myaccount.google.com/apppasswords
# 2. Crea una "ContraseÃ±a de aplicaciÃ³n" (necesitas 2FA activado)
# 3. Pega la contraseÃ±a de 16 caracteres abajo
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
SMTP_EMAIL    = "smart.tech6913@gmail.com"
SMTP_PASSWORD = "jpjv hjev eies wqnx"
SMTP_HOST     = "smtp.gmail.com"
SMTP_PORT     = 587


# â”€â”€ CSS base embebido â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
# Los clientes de correo mÃ³vil (Gmail App, Apple Mail, Outlook) leen
# <style> en el <head>. Esto activa el layout responsive sin JS.
RESPONSIVE_CSS = """
<style>
  /* Reset bÃ¡sico para clientes de correo */
  body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
  table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
  img { -ms-interpolation-mode: bicubic; border: 0; display: block; }

  /* Wrapper principal */
  .email-wrapper { width: 100%; background: #060D17; }
  .email-container { max-width: 600px; margin: 0 auto; }

  /* Tablas de productos */
  .product-table { width: 100%; border-collapse: collapse; }
  .product-table th, .product-table td { padding: 12px; }

  /* â”€â”€ MÃ“VIL: pantallas menores a 600px â”€â”€ */
  @media only screen and (max-width: 600px) {
    .email-container { width: 100% !important; }
    .header-pad    { padding: 20px 16px !important; }
    .body-pad      { padding: 16px !important; }
    .footer-pad    { padding: 16px !important; }
    .total-block   { padding: 14px 16px !important; }
    .info-block    { padding: 16px !important; }
    .status-block  { padding: 20px 16px !important; }
    .status-icon   { font-size: 36px !important; }
    .status-label  { font-size: 18px !important; }
    .total-amount  { font-size: 18px !important; }
    h1.logo-title  { font-size: 20px !important; }

    /* En mÃ³vil ocultamos columnas CANT y PRECIO, solo nombre + subtotal */
    .col-cant, .col-precio { display: none !important; width: 0 !important; overflow: hidden !important; max-height: 0 !important; padding: 0 !important; }
    .col-nombre { width: 70% !important; }
    .col-subtotal { width: 30% !important; }
  }
</style>
"""


def _wrap_email(inner_html: str) -> str:
    """
    Envuelve el contenido en una estructura de tabla compatible
    con todos los clientes de correo (Outlook, Gmail, Apple Mail, etc.)
    """
    return f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>SmartTech Store</title>
  {RESPONSIVE_CSS}
</head>
<body style="margin:0; padding:0; background:#060D17;">
  <!-- Wrapper externo: fuerza fondo en todos los clientes -->
  <table role="presentation" class="email-wrapper" width="100%" cellpadding="0" cellspacing="0" border="0">
    <tr>
      <td align="center" style="padding: 0;">
        <!-- Contenedor central 600px -->
        <table role="presentation" class="email-container" width="600" cellpadding="0" cellspacing="0" border="0"
               style="max-width:600px; background:#060D17; font-family: Arial, Helvetica, sans-serif;">
          {inner_html}
        </table>
      </td>
    </tr>
  </table>
</body>
</html>"""


def send_email(to_email: str, subject: str, html_body: str):
    """EnvÃ­a un email HTML usando Gmail SMTP"""
    try:
        msg = MIMEMultipart("alternative")
        msg["From"]    = f"SmartTech Store <{SMTP_EMAIL}>"
        msg["To"]      = to_email
        msg["Subject"] = subject

        msg.attach(MIMEText(html_body, "html", "utf-8"))

        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_EMAIL, SMTP_PASSWORD)
            server.sendmail(SMTP_EMAIL, to_email, msg.as_string())

        print(f"EMAIL ENVIADO a {to_email}: {subject}")
        return True
    except Exception as e:
        print(f"ERROR EMAIL: {e}")
        return False


def build_order_confirmation(
    nombre: str,
    items: list,
    total: float,
    metodo: str,
    direccion: str,
    fecha_entrega: str
) -> str:
    """
    Genera HTML de confirmaciÃ³n de compra totalmente responsive.
    Usa tablas anidadas para compatibilidad mÃ¡xima con clientes de correo.
    """

    # â”€â”€ Filas de productos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    items_rows = ""
    for item in items:
        items_rows += f"""
          <tr>
            <td class="col-nombre" style="padding:12px; border-bottom:1px solid #1A2E44;
                color:#EFF6FF; font-size:14px; word-break:break-word;">
              {item['name']}
            </td>
            <td class="col-cant" style="padding:12px; border-bottom:1px solid #1A2E44;
                color:#7A9BB5; text-align:center; font-size:14px; white-space:nowrap;">
              {item['quantity']}
            </td>
            <td class="col-precio" style="padding:12px; border-bottom:1px solid #1A2E44;
                color:#00D4FF; text-align:right; font-size:14px; white-space:nowrap;">
              ${item['price']:,.0f}
            </td>
            <td class="col-subtotal" style="padding:12px; border-bottom:1px solid #1A2E44;
                color:#00D4FF; text-align:right; font-size:14px; font-weight:bold; white-space:nowrap;">
              ${item['subtotal']:,.0f}
            </td>
          </tr>"""

    metodo_label = {
        "tarjeta":        "Tarjeta de crÃ©dito",
        "nequi":          "Nequi",
        "contra_entrega": "Contra entrega"
    }.get(metodo, metodo)

    inner = f"""
      <!-- â•â• HEADER â•â• -->
      <tr>
        <td class="header-pad" style="background:#0D1F33; padding:30px 24px;
            text-align:center; border-bottom:2px solid #00D4FF;">
          <h1 class="logo-title" style="color:#00D4FF; margin:0; font-size:24px;
              font-family:Arial,sans-serif; font-weight:bold;">SmartTech Store</h1>
          <p style="color:#7A9BB5; margin:6px 0 0; font-size:12px;
              letter-spacing:3px; font-family:Arial,sans-serif;">CONFIRMACIÃ“N DE COMPRA</p>
        </td>
      </tr>

      <!-- â•â• CUERPO â•â• -->
      <tr>
        <td class="body-pad" style="padding:28px 24px;">

          <!-- Saludo -->
          <p style="color:#EFF6FF; font-size:16px; margin:0 0 6px;
              font-family:Arial,sans-serif;">Â¡Hola <strong>{nombre}</strong>! ðŸ‘‹</p>
          <p style="color:#7A9BB5; font-size:14px; margin:0 0 20px;
              font-family:Arial,sans-serif;">Tu compra fue procesada exitosamente. AquÃ­ tienes el detalle:</p>

          <!-- Tabla de productos -->
          <table role="presentation" class="product-table" width="100%"
                 cellpadding="0" cellspacing="0" border="0"
                 style="background:#111E2E; border-radius:10px; overflow:hidden;">
            <thead>
              <tr style="background:#0D1F33;">
                <th class="col-nombre" align="left"
                    style="padding:12px; color:#7A9BB5; font-size:11px;
                           font-family:Arial,sans-serif; font-weight:600; letter-spacing:1px;">
                  PRODUCTO
                </th>
                <th class="col-cant" align="center"
                    style="padding:12px; color:#7A9BB5; font-size:11px;
                           font-family:Arial,sans-serif; font-weight:600; letter-spacing:1px;">
                  CANT
                </th>
                <th class="col-precio" align="right"
                    style="padding:12px; color:#7A9BB5; font-size:11px;
                           font-family:Arial,sans-serif; font-weight:600; letter-spacing:1px;">
                  PRECIO
                </th>
                <th class="col-subtotal" align="right"
                    style="padding:12px; color:#7A9BB5; font-size:11px;
                           font-family:Arial,sans-serif; font-weight:600; letter-spacing:1px;">
                  SUBTOTAL
                </th>
              </tr>
            </thead>
            <tbody>
              {items_rows}
            </tbody>
          </table>

          <!-- Total -->
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"
                 style="margin-top:16px;">
            <tr>
              <td class="total-block" align="right"
                  style="background:#00D4FF; padding:16px 20px; border-radius:10px;">
                <span style="color:#060D17; font-size:14px;
                    font-family:Arial,sans-serif;">Total pagado:&nbsp;</span>
                <span class="total-amount" style="color:#060D17; font-size:22px;
                    font-weight:bold; font-family:Arial,sans-serif;">${total:,.0f} COP</span>
              </td>
            </tr>
          </table>

          <!-- Info de envÃ­o -->
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"
                 style="margin-top:16px; background:#111E2E; border-radius:10px;
                        border:1px solid #1A2E44;">
            <tr>
              <td class="info-block" style="padding:20px;">
                <p style="color:#EFF6FF; margin:0 0 10px; font-size:13px;
                    font-family:Arial,sans-serif;">
                  ðŸ“¦ <strong>MÃ©todo de pago:</strong> {metodo_label}
                </p>
                <p style="color:#EFF6FF; margin:0 0 10px; font-size:13px;
                    font-family:Arial,sans-serif; word-break:break-word;">
                  ðŸ“ <strong>DirecciÃ³n:</strong> {direccion}
                </p>
                <p style="color:#EFF6FF; margin:0; font-size:13px;
                    font-family:Arial,sans-serif;">
                  ðŸ“… <strong>Fecha de entrega:</strong> {fecha_entrega}
                </p>
              </td>
            </tr>
          </table>

          <!-- Estado -->
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"
                 style="margin-top:14px; background:#111E2E; border-radius:10px;
                        border:1px solid #1A2E44;">
            <tr>
              <td class="status-block" align="center" style="padding:24px 20px;">
                <p style="color:#7A9BB5; margin:0 0 8px; font-size:11px;
                    letter-spacing:2px; font-family:Arial,sans-serif;">ESTADO ACTUAL</p>
                <p style="color:#00D4FF; margin:0; font-size:20px;
                    font-weight:bold; font-family:Arial,sans-serif;">âœ… Pagado</p>
              </td>
            </tr>
          </table>

        </td>
      </tr>

      <!-- â•â• FOOTER â•â• -->
      <tr>
        <td class="footer-pad" align="center"
            style="background:#0D1F33; padding:20px 24px; border-top:1px solid #1A2E44;">
          <p style="color:#7A9BB5; font-size:11px; margin:0;
              font-family:Arial,sans-serif;">SmartTech Store â€” Tu tienda de tecnologÃ­a</p>
          <p style="color:#7A9BB5; font-size:11px; margin:5px 0 0;
              font-family:Arial,sans-serif;">
            Este correo fue enviado automÃ¡ticamente, no respondas a este mensaje.
          </p>
        </td>
      </tr>
    """

    return _wrap_email(inner)


def build_status_update(
    nombre: str,
    pedido_id: int,
    estado: str,
    items_summary: str
) -> str:
    """
    Genera HTML de actualizaciÃ³n de estado totalmente responsive.
    """

    estado_info = {
        "pagado":         {"icon": "âœ…", "color": "#00D4FF", "label": "Pagado"},
        "en_preparacion": {"icon": "ðŸ“¦", "color": "#FFB74D", "label": "En preparaciÃ³n"},
        "enviado":        {"icon": "ðŸšš", "color": "#7C3AED", "label": "Enviado"},
        "entregado":      {"icon": "ðŸŽ‰", "color": "#4CAF50", "label": "Entregado"},
        "cancelado":      {"icon": "âŒ", "color": "#FF5252", "label": "Cancelado"},
    }

    info = estado_info.get(estado, {"icon": "ðŸ“‹", "color": "#7A9BB5", "label": estado})

    inner = f"""
      <!-- â•â• HEADER â•â• -->
      <tr>
        <td class="header-pad" style="background:#0D1F33; padding:30px 24px;
            text-align:center; border-bottom:2px solid #00D4FF;">
          <h1 class="logo-title" style="color:#00D4FF; margin:0; font-size:24px;
              font-family:Arial,sans-serif; font-weight:bold;">SmartTech Store</h1>
          <p style="color:#7A9BB5; margin:6px 0 0; font-size:12px;
              letter-spacing:3px; font-family:Arial,sans-serif;">ACTUALIZACIÃ“N DE PEDIDO</p>
        </td>
      </tr>

      <!-- â•â• CUERPO â•â• -->
      <tr>
        <td class="body-pad" style="padding:28px 24px;">

          <p style="color:#EFF6FF; font-size:16px; margin:0 0 6px;
              font-family:Arial,sans-serif;">Hola <strong>{nombre}</strong>,</p>
          <p style="color:#7A9BB5; font-size:14px; margin:0 0 20px;
              font-family:Arial,sans-serif;">
            Tu pedido <strong>#{pedido_id}</strong> ha sido actualizado:
          </p>

          <!-- Badge de estado -->
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"
                 style="background:#111E2E; border-radius:14px; border:1px solid #1A2E44;">
            <tr>
              <td class="status-block" align="center" style="padding:32px 20px;">
                <p class="status-icon" style="font-size:48px; margin:0; line-height:1;">
                  {info['icon']}
                </p>
                <p class="status-label" style="color:{info['color']}; font-size:22px;
                    font-weight:bold; margin:12px 0 0; font-family:Arial,sans-serif;">
                  {info['label']}
                </p>
              </td>
            </tr>
          </table>

          <!-- Resumen de productos -->
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"
                 style="margin-top:16px; background:#111E2E; border-radius:10px;
                        border:1px solid #1A2E44;">
            <tr>
              <td class="info-block" style="padding:16px 20px;">
                <p style="color:#7A9BB5; margin:0 0 6px; font-size:11px;
                    letter-spacing:2px; font-family:Arial,sans-serif;">PRODUCTOS</p>
                <p style="color:#EFF6FF; margin:0; font-size:13px;
                    font-family:Arial,sans-serif; word-break:break-word;">
                  {items_summary}
                </p>
              </td>
            </tr>
          </table>

        </td>
      </tr>

      <!-- â•â• FOOTER â•â• -->
      <tr>
        <td class="footer-pad" align="center"
            style="background:#0D1F33; padding:20px 24px; border-top:1px solid #1A2E44;">
          <p style="color:#7A9BB5; font-size:11px; margin:0;
              font-family:Arial,sans-serif;">SmartTech Store â€” Tu tienda de tecnologÃ­a</p>
        </td>
      </tr>
    """

    return _wrap_email(inner)