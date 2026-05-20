module IconHelper
  ICONS = {
    home:    %(<path d="M3 10.5L12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1v-9.5z"/>),
    inbox:   %(<path d="M3 13v6a1 1 0 0 0 1 1h16a1 1 0 0 0 1-1v-6m-18 0 3-9h12l3 9m-18 0h6l1 2h4l1-2h6"/>),
    bulb:    %(<path d="M9 18h6m-5 3h4M12 3a6 6 0 0 1 4 10.5c-.7.6-1 1.5-1 2.5H9c0-1-.3-1.9-1-2.5A6 6 0 0 1 12 3z"/>),
    triage:  %(<path d="M4 5h16M7 12h10M10 19h4"/>),
    doc:     %(<path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9l-6-6zm0 0v6h6M8 13h8M8 17h5"/>),
    folder:  %(<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7z"/>),
    chart:   %(<path d="M4 20V10m6 10V4m6 16v-8m6 8H2"/>),
    calendar:%(<path d="M3 7a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7zm0 4h18M8 3v4M16 3v4"/>),
    book:    %(<path d="M4 4.5A2.5 2.5 0 0 1 6.5 2H20v17H6.5A2.5 2.5 0 0 0 4 21.5v-17zM4 19.5h16"/>),
    cog:     %(<path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>),
    plus:    %(<path d="M12 5v14M5 12h14"/>),
    arrow:   %(<path d="M5 12h14m-5-5 5 5-5 5"/>),
    "chev-d":%(<path d="m6 9 6 6 6-6"/>),
    "chev-r":%(<path d="m9 6 6 6-6 6"/>),
    check:   %(<path d="m5 12 5 5L20 7"/>),
    x:       %(<path d="m6 6 12 12M6 18 18 6"/>),
    search:  %(<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>),
    bell:    %(<path d="M6 16V11a6 6 0 1 1 12 0v5l1.5 2H4.5L6 16zM10 20a2 2 0 0 0 4 0"/>),
    filter:  %(<path d="M3 5h18l-7 9v6l-4-2v-4z"/>),
    upload:  %(<path d="M12 16V4m0 0-4 4m4-4 4 4M4 16v3a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-3"/>),
    download:%(<path d="M12 4v12m0 0-4-4m4 4 4-4M4 20h16"/>),
    file:    %(<path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9l-6-6zm0 0v6h6"/>),
    pdf:     %(<path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9l-6-6zm0 0v6h6M9 14h1.5a1.5 1.5 0 0 1 0 3H9v3m4 0v-6h1.5a1.5 1.5 0 0 1 0 3H13"/>),
    xls:     %(<path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9l-6-6zm0 0v6h6m-9.5 5.5 4 5m-4 0 4-5"/>),
    link:    %(<path d="M10 13a5 5 0 0 0 7 0l3-3a5 5 0 0 0-7-7l-1 1m1 9a5 5 0 0 0-7 0l-3 3a5 5 0 0 0 7 7l1-1"/>),
    flag:    %(<path d="M4 21V4h13l-2 4 2 4H4"/>),
    msg:     %(<path d="M21 11.5a8.4 8.4 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.4 8.4 0 0 1-3.8-.9L3 21l1.9-5.7a8.4 8.4 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.4 8.4 0 0 1 3.8-.9 8.5 8.5 0 0 1 8.5 8.5z"/>),
    user:    %(<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>),
    sparkle: %(<path d="M12 3 13.5 9 19 10.5 13.5 12 12 18 10.5 12 5 10.5 10.5 9 12 3z"/>),
    shield:  %(<path d="M12 3 4 6v6a8 8 0 0 0 8 8 8 8 0 0 0 8-8V6l-8-3z"/>),
    eye:     %(<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>),
    dots:    %(<circle cx="5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/>),
    "n1":    %(<circle cx="12" cy="12" r="9"/><path d="M11 8h1v8M9 16h6"/>),
    "n2":    %(<circle cx="12" cy="12" r="9"/><path d="M9 9a3 3 0 1 1 6 0c0 3-6 3-6 7h6"/>),
    "n3":    %(<circle cx="12" cy="12" r="9"/><path d="M9 8h6l-3 4a3 3 0 1 1-3 3"/>),
    logout:  %(<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/>)
  }.freeze

  def icon(name, size: 16, class_name: nil)
    body = ICONS[name.to_sym] || ICONS[:bulb]
    cls = "tsuru-icon #{class_name}".strip
    content_tag(:svg, body.html_safe,
                viewBox: "0 0 24 24",
                width: size, height: size,
                class: cls,
                "aria-hidden": "true")
  end
end
