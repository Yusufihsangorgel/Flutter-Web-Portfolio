export type PortfolioArtifact = {
  asset: string;
  alt: string;
  caption: string;
  width: number;
  height: number;
  compact?: PortfolioArtifact;
};

export type PortfolioSystem = {
  id: string;
  name: string;
  kind: string;
  featured: boolean;
  ownership: string;
  evidence: Array<{ label: string; url: string }>;
  artifact: PortfolioArtifact;
};

export type PortfolioContribution = {
  featured: boolean;
  project: string;
  status: string;
  title: string;
};

export type PortfolioTestData = {
  content_version: string;
  site: {
    locales: string[];
    social_image: string;
    title: string;
    url: string;
  };
  profile: {
    display_name: {
      accessible: string;
      accent: string;
      primary: string;
    };
    email: string;
    focus: string[];
    headline: string;
    links: Array<{ label: string; url: string }>;
    location: string;
    role: string;
    since: string;
  };
  experience: Array<{ company: string }>;
  contributions: PortfolioContribution[];
  systems: PortfolioSystem[];
};

export type InterfaceTestData = {
  accessibility: {
    back_to_top: string;
    load_failure: string;
    retry: string;
    skip_to_content: string;
  };
  home_section: { view_work: string };
  projects_section: {
    open_evidence: string;
    select_evidence: string;
  };
};
