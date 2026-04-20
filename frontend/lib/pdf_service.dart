import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {

  static Future<List<int>> generatePdf(Map fac, String message) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Demande de stage",
                style: pw.TextStyle(fontSize: 22)),

            pw.Text("Objet : Demande de stage"),

            pw.SizedBox(height: 10),

            pw.Text("Nom : ${fac['name']}"),
            pw.Text("Email : ${fac['email']}"),
            pw.Text("Téléphone : ${fac['phone']}"),
            pw.Text("Pays : ${fac['pays']}"),

            pw.SizedBox(height: 20),

            pw.Text("Message :",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

            pw.Text(message),

            pw.SizedBox(height: 30),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text("Cordialement"),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }
}