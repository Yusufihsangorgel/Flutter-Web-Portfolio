typedef PortfolioExperienceTranslation = ({
  String role,
  String domain,
  String period,
  String summary,
  List<String> evidence,
});

typedef PortfolioExperienceFields = ({
  String id,
  String company,
  String role,
  String domain,
  String period,
  bool current,
  String summary,
  List<String> evidence,
});

final class PortfolioExperience {
  PortfolioExperience(PortfolioExperienceFields fields)
    : id = fields.id,
      company = fields.company,
      role = fields.role,
      domain = fields.domain,
      period = fields.period,
      current = fields.current,
      summary = fields.summary,
      evidence = List.unmodifiable(fields.evidence);

  PortfolioExperience copyWith(PortfolioExperienceTranslation changes) =>
      PortfolioExperience((
        id: id,
        company: company,
        role: changes.role,
        domain: changes.domain,
        period: changes.period,
        current: current,
        summary: changes.summary,
        evidence: changes.evidence,
      ));

  Map<String, Object?> toJson() => {
    'id': id,
    'company': company,
    'role': role,
    'domain': domain,
    'period': period,
    'current': current,
    'summary': summary,
    'evidence': evidence,
  };

  final String id;
  final String company;
  final String role;
  final String domain;
  final String period;
  final bool current;
  final String summary;
  final List<String> evidence;
}
