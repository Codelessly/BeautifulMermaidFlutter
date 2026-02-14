import 'package:beautiful_mermaid/beautiful_mermaid.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beautiful Mermaid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7aa2f7),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  String _themeName = 'tokyo-night';
  int _diagramIndex = 0;

  MermaidColors get _colors => MermaidTheme.all[_themeName]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colors.bg,
      appBar: AppBar(
        title: const Text('Beautiful Mermaid'),
        backgroundColor: Colors.transparent,
        foregroundColor: _colors.fg,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Diagram type chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _diagrams.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = i == _diagramIndex;
                return FilterChip(
                  label: Text(_diagrams[i].title),
                  selected: selected,
                  onSelected: (_) => setState(() => _diagramIndex = i),
                  backgroundColor: _colors.bg,
                  selectedColor: _colors.accent ?? _colors.fg,
                  labelStyle: TextStyle(
                    color: selected ? _colors.bg : _colors.fg,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color:
                        (_colors.border ?? _colors.fg).withValues(alpha: 0.3),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Theme dots
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: MermaidTheme.all.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final entry = MermaidTheme.all.entries.elementAt(i);
                final selected = entry.key == _themeName;
                return GestureDetector(
                  onTap: () => setState(() => _themeName = entry.key),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: entry.value.bg,
                      border: Border.all(
                        color: selected
                            ? (entry.value.accent ?? entry.value.fg)
                            : entry.value.fg.withValues(alpha: 0.2),
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: entry.value.fg,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),

          Text(
            _themeName,
            style: TextStyle(
              color: (_colors.muted ?? _colors.fg).withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),

          // Diagram — single persistent WebView, no key-based recreation
          Expanded(
            child: MermaidDiagram(
              source: _diagrams[_diagramIndex].source,
              colors: _colors,
            ),
          ),
        ],
      ),
    );
  }
}

class _Diagram {
  final String title;
  final String source;
  const _Diagram(this.title, this.source);
}

const _diagrams = [
  _Diagram('Flowchart', '''graph TD
    A[Start] --> B{Is it working?}
    B -->|Yes| C[Great!]
    B -->|No| D[Debug]
    D --> E[Check Logs]
    E --> F{Found Issue?}
    F -->|Yes| G[Fix It]
    F -->|No| H[Ask for Help]
    G --> B
    H --> B
    C --> I([Done])'''),
  _Diagram('Sequence', '''sequenceDiagram
    participant U as User
    participant A as App
    participant S as Server
    participant D as Database
    U->>A: Open App
    A->>S: GET /api/data
    S->>D: SELECT * FROM items
    D-->>S: Results
    S-->>A: JSON Response
    A-->>U: Display Data
    Note over U,A: User interacts
    U->>A: Update Item
    A->>S: PUT /api/items/1
    S->>D: UPDATE items SET...
    D-->>S: OK
    S-->>A: 200 Success
    A-->>U: Show Confirmation'''),
  _Diagram('State', '''stateDiagram-v2
    [*] --> Idle
    Idle --> Loading : fetch()
    Loading --> Success : data received
    Loading --> Error : request failed
    Success --> Idle : reset()
    Error --> Loading : retry()
    Error --> Idle : dismiss()
    state Loading {
        [*] --> Requesting
        Requesting --> Parsing : response received
        Parsing --> [*]
    }'''),
  _Diagram('Class', '''classDiagram
    class Animal {
        +String name
        +int age
        +makeSound() void
        +move() void
    }
    class Dog {
        +String breed
        +fetch() void
        +bark() void
    }
    class Cat {
        +bool isIndoor
        +purr() void
        +scratch() void
    }
    class Shelter {
        -List~Animal~ animals
        +adopt(Animal a) void
        +rescue(Animal a) void
    }
    Animal <|-- Dog
    Animal <|-- Cat
    Shelter "1" --> "*" Animal : houses'''),
  _Diagram('ER Diagram', '''erDiagram
    CUSTOMER ||--o{ ORDER : places
    CUSTOMER {
        string name PK
        string email UK
        string address
    }
    ORDER ||--|{ LINE_ITEM : contains
    ORDER {
        int id PK
        date created
        string status
    }
    LINE_ITEM }o--|| PRODUCT : references
    LINE_ITEM {
        int quantity
        float price
    }
    PRODUCT {
        int id PK
        string name
        float unitPrice
        string category
    }'''),
];
