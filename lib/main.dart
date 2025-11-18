import 'package:flutter/material.dart';

void main() => runApp(const SimpleNotesApp());

class Note {
  final String id;
  String title;
  String body;

  Note({required this.id, required this.title, required this.body});

  Note copyWith({String? title, String? body}) => Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
      );
}

class SimpleNotesApp extends StatelessWidget {
  const SimpleNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Notes',
      theme: ThemeData(useMaterial3: true),
      home: const NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final List<Note> _notes = [
    Note(id: '1', title: 'Пример', body: 'Это пример заметки'),
  ];
  final TextEditingController _searchController = TextEditingController();
  List<Note> _filteredNotes = [];

  @override
  void initState() {
    super.initState();
    _filteredNotes = _notes;
    _searchController.addListener(_filterNotes);
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _notes.where((note) => 
        note.title.toLowerCase().contains(query) || 
        note.body.toLowerCase().contains(query)
      ).toList();
    });
  }

  Future<void> _addNote() async {
    final newNote = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => const EditNotePage()),
    );
    if (newNote != null) {
      setState(() {
        _notes.add(newNote);
        _filterNotes();
      });
    }
  }

  Future<void> _editNote(Note note) async {
    final updated = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => EditNotePage(existing: note)),
    );
    if (updated != null) {
      setState(() {
        final index = _notes.indexWhere((n) => n.id == updated.id);
        if (index != -1) _notes[index] = updated;
        _filterNotes();
      });
    }
  }

  void _deleteNote(Note note) {
    setState(() {
      _notes.removeWhere((n) => n.id == note.id);
      _filterNotes();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Заметка удалена'),
        action: SnackBarAction(
          label: 'Отмена',
          onPressed: () {
            setState(() {
              _notes.add(note);
              _filterNotes();
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: NotesSearchDelegate(_notes, _editNote),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск заметок...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredNotes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.note_add, size: 64, color: Colors.grey),
                        Text('Нет заметок', style: TextStyle(fontSize: 18)),
                        Text('Нажмите + чтобы создать первую заметку'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = _filteredNotes[index];
                      return Dismissible(
                        key: ValueKey(note.id),
                        background: Container(color: Colors.red),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteNote(note),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.note_outlined),
                            title: Text(
                              note.title.isEmpty ? '(без названия)' : note.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              note.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _editNote(note),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteNote(note),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class EditNotePage extends StatefulWidget {
  final Note? existing;
  const EditNotePage({super.key, this.existing});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  final _formKey = GlobalKey<FormState>();
  late String _title = widget.existing?.title ?? '';
  late String _body = widget.existing?.body ?? '';

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final result = (widget.existing == null)
        ? Note(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: _title,
            body: _body,
          )
        : widget.existing!.copyWith(title: _title, body: _body);

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактировать' : 'Новая заметка'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(
                  labelText: 'Заголовок',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
                onSaved: (v) => _title = v!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _body,
                decoration: const InputDecoration(
                  labelText: 'Текст заметки',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 5,
                maxLines: 10,
                onSaved: (v) => _body = v!.trim(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Введите текст заметки'
                    : null,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Сохранить заметку'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotesSearchDelegate extends SearchDelegate {
  final List<Note> notes;
  final Function(Note) onEditNote;

  NotesSearchDelegate(this.notes, this.onEditNote);

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = notes.where((note) =>
        note.title.toLowerCase().contains(query.toLowerCase()) ||
        note.body.toLowerCase().contains(query.toLowerCase()));

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final note = results.elementAt(index);
        return ListTile(
          title: Text(note.title.isEmpty ? '(без названия)' : note.title),
          subtitle: Text(note.body),
          onTap: () {
            close(context, null);
            onEditNote(note);
          },
        );
      },
    );
  }
}