import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:web/web.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// Application itself.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Flutter Demo', home: HomePage());
  }
}

/// [Widget] displaying the home page consisting of an image the the buttons.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// State of a [HomePage].
class _HomePageState extends State<HomePage> {
  /// A [TextEditingController] for image link which is to be used to set image
  /// source in <img> element.
  final TextEditingController _imageLinkController = TextEditingController();

  /// A [ContextMenuController] to hide and show the context menu.
  final ContextMenuController _contextMenuController = ContextMenuController();

  /// A [StreamSubscription] for double clicks stream.
  StreamSubscription? _onDoubleClickStreamSubscription;

  /// A [StreamSubscription] for Full screen mode changes stream.
  StreamSubscription? _onFullScreenStreamSubscription;

  /// [GlobalKey] used to check floating action button's location.
  final GlobalKey _fabGlobalKey = GlobalKey();

  /// Keeps track whether screen shown image is in full screen or not.
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _registerImageElementFactory();
  }

  @override
  void dispose() {
    _imageLinkController.dispose();
    _contextMenuController.remove();
    _onDoubleClickStreamSubscription?.cancel();
    _onFullScreenStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const HtmlElementView(
                    viewType: 'image-view',
                    hitTestBehavior: PlatformViewHitTestBehavior.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageLinkController,
                    decoration: const InputDecoration(hintText: 'Image URL'),
                  ),
                ),
                ElevatedButton(
                  onPressed: _setImage,
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(0, 12, 0, 12),
                    child: Icon(Icons.arrow_forward),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: _fabGlobalKey,
        onPressed: _showContextMenu,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Shows context menu above floating action button.
  void _showContextMenu() {
    final fabRenderBox =
        _fabGlobalKey.currentContext?.findRenderObject() as RenderBox?;
    final fabPosition = fabRenderBox?.localToGlobal(Offset.zero);

    if (fabPosition != null) {
      final contextMenuPosition = Offset(
        fabPosition.dx - 30,
        fabPosition.dy - 60,
      );
      _contextMenuController.show(
        context: context,
        contextMenuBuilder: (context) {
          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: _contextMenuController.remove,
                child: const SizedBox.expand(
                  child: ColoredBox(color: Colors.black54),
                ),
              ),
              AdaptiveTextSelectionToolbar.buttonItems(
                buttonItems: [
                  ContextMenuButtonItem(
                    onPressed: () {
                      _requestFullScreen();
                      _contextMenuController.remove();
                    },
                    label: 'Enter fullscreen',
                  ),
                  ContextMenuButtonItem(
                    onPressed: () {
                      if (_isFullScreen) {
                        document.exitFullscreen();
                      }
                      _contextMenuController.remove();
                    },
                    label: 'Exit fullscreen',
                  ),
                ],
                anchors: TextSelectionToolbarAnchors(
                  primaryAnchor: contextMenuPosition,
                ),
              ),
            ],
          );
        },
      );
    }
  }

  /// Sets image url in Image element. The set image will be shown in the center
  /// of the screen.
  void _setImage() {
    if (_imageLinkController.text.isEmpty) return;
    final element = document.getElementById('image_element');
    if (element != null && element.isA<HTMLImageElement>()) {
      final imageElement = element as HTMLImageElement;
      imageElement.src = _imageLinkController.text;
    }
  }

  /// Registers <img> element and streams.
  void _registerImageElementFactory() {
    ui_web.platformViewRegistry.registerViewFactory('image-view', (
      int viewId, {
      Object? params,
    }) {
      final imageElement =
          HTMLImageElement()
            ..id = 'image_element'
            ..style.width = '100%'
            ..style.borderRadius = '12px'
            ..style.height = '100%';
      _listenForStreams(imageElement);
      return imageElement;
    });
  }

  /// Registers StreamSubscriptions to listen to full screen mode change and
  /// double clicks.
  void _listenForStreams(HTMLImageElement imageElement) {
    _onFullScreenStreamSubscription = const EventStreamProvider<Event>(
      'fullscreenchange',
    ).forElement(imageElement).listen((event) {
      if (document.fullscreenElement != null) {
        _isFullScreen = true;
      } else {
        _isFullScreen = false;
      }
    });
    _onDoubleClickStreamSubscription = imageElement.onDoubleClick.listen((
      event,
    ) {
      _requestFullScreen();
    });
  }

  /// Shows image in the full screen.
  void _requestFullScreen() {
    _isFullScreen = true;
    document.querySelector('#image_element')?.requestFullscreen();
  }
}
