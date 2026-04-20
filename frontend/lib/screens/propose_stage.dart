void send(dynamic start, dynamic subject, dynamic company, dynamic title,  end) async {
  var api;
  await api.proposeStage({
    "title": title.text,
    "company": company.text,
    "subject": subject.text,
    "startDate": start.text,
    "endDate": end.text,
    "studentId": 1
  });
}