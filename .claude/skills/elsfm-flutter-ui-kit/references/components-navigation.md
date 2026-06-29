# Navigation Components

App-wide navigation UI using Material 3 NavigationBar and AppBar.

## AppBar

Top app bar with title, actions, and menu.

```dart
AppBar(
  title: const Text('Library'),
  centerTitle: false,
  elevation: 0,
  actions: [
    IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: () => _showMenu(context),
    ),
  ],
)

// With search
AppBar(
  title: TextField(
    decoration: InputDecoration(
      hintText: 'Search tracks, artists...',
      border: InputBorder.none,
      prefixIcon: const Icon(Icons.search),
    ),
  ),
  elevation: 4,
)

// Custom with leading back button
AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => context.pop(),
  ),
  title: const Text('Album'),
)
```

## BottomNavigationBar (NavigationBar)

Material 3 navigation bar at bottom with 4 main tabs.

```dart
NavigationBar(
  selectedIndex: _selectedIndex,
  onDestinationSelected: (int index) {
    setState(() => _selectedIndex = index);
    context.go(_navigationRoutes[index]);
  },
  destinations: const [
    NavigationDestination(
      selectedIcon: Icon(Icons.home),
      icon: Icon(Icons.home_outlined),
      label: 'Home',
    ),
    NavigationDestination(
      selectedIcon: Icon(Icons.search),
      icon: Icon(Icons.search),
      label: 'Search',
    ),
    NavigationDestination(
      selectedIcon: Icon(Icons.library_music),
      icon: Icon(Icons.library_music_outlined),
      label: 'Library',
    ),
    NavigationDestination(
      selectedIcon: Icon(Icons.person),
      icon: Icon(Icons.person_outlined),
      label: 'Profile',
    ),
  ],
)
```

### Navigation Structure
```
┌──────────────────────────────┐
│ [≡] AppBar Title      [⋮]   │
├──────────────────────────────┤
│                              │
│ Main Screen Content          │
│                              │
│ ┌────────────────────────┐   │
│ │ MiniPlayer             │   │
│ └────────────────────────┘   │
├──────────────────────────────┤
│ 🏠 🔍 📚 👤                   │
│ Home Search Library Profile   │
└──────────────────────────────┘
```

## Drawer Navigation

Side drawer for additional navigation (menu, settings, logout).

```dart
Scaffold(
  appBar: AppBar(title: const Text('Home')),
  drawer: Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(user.image ?? ''),
                radius: 32,
              ),
              const SizedBox(height: 8),
              Text(user.name, style: const TextStyle(color: Colors.white)),
              Text(user.email, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        // Menu items
        ListTile(
          leading: const Icon(Icons.favorite),
          title: const Text('Favorites'),
          onTap: () {
            Navigator.pop(context);
            context.go('/favorites');
          },
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Downloads'),
          onTap: () {
            Navigator.pop(context);
            context.go('/downloads');
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () {
            Navigator.pop(context);
            context.go('/settings');
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () {
            Navigator.pop(context);
            ref.read(authNotifierProvider.notifier).logout();
          },
        ),
      ],
    ),
  ),
  body: child,
)
```

## Breadcrumbs

Navigation trail for nested screens (optional, not in current ELSFM).

```dart
Breadcrumbs(
  items: [
    BreadcrumbItem(label: 'Home', onTap: () => context.go('/home')),
    BreadcrumbItem(label: 'Albums', onTap: () => context.go('/albums')),
    BreadcrumbItem(label: 'Album Name', onTap: null), // Current page
  ],
)
```

## Tab Navigation

For screens with multiple views (Albums, Artists, Playlists in Library).

```dart
class LibraryScreen extends StatefulWidget {
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Library'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tracks'),
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TracksTab(),
          AlbumsTab(),
          ArtistsTab(),
        ],
      ),
    );
  }
}
```

## ModalBottomSheet

Slide-up menu for actions (add to playlist, download, share).

```dart
showModalBottomSheet<void>(
  context: context,
  builder: (BuildContext context) {
    return Container(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to Playlist'),
            onTap: () {
              Navigator.pop(context);
              _showPlaylistPicker();
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download'),
            onTap: () {
              Navigator.pop(context);
              downloadTrack(track);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              Share.share(track.url);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Remove'),
            onTap: () {
              Navigator.pop(context);
              removeFromLibrary(track);
            },
          ),
        ],
      ),
    );
  },
);
```

## AlertDialog

Modal dialog for confirmations and important messages.

```dart
showDialog<void>(
  context: context,
  builder: (BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Playlist?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            deletePlaylist(playlist);
            Navigator.pop(context);
          },
          child: const Text('Delete'),
        ),
      ],
    );
  },
);
```

## Floating Action Button (FAB)

Primary action button floating above content (optional in ELSFM).

```dart
FloatingActionButton(
  onPressed: () => createNewPlaylist(),
  child: const Icon(Icons.add),
)

// Extended FAB
FloatingActionButton.extended(
  onPressed: () => createNewPlaylist(),
  icon: const Icon(Icons.add),
  label: const Text('New Playlist'),
)
```

## Snackbar / Toast

Brief messages at bottom of screen (downloads, shares, errors).

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Added to playlist'),
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () => undoLastAction(),
    ),
  ),
);

// Error variant
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Failed to download'),
    backgroundColor: Theme.of(context).colorScheme.error,
  ),
);
```
