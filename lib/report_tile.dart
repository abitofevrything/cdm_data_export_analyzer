import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ReportTile extends StatelessWidget {
  final Widget child;
  final int crossAxisCellCount;
  final int mainAxisCellCount;

  const ReportTile({
    super.key,
    required this.child,
    this.crossAxisCellCount = 1,
    this.mainAxisCellCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    return StaggeredGridTile.count(
      crossAxisCellCount: crossAxisCellCount,
      mainAxisCellCount: mainAxisCellCount,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade900,
        ),
        child: child,
      ),
    );
  }
}

class ScrollingReportTile extends StatefulWidget {
  final Widget title;
  final List<Widget> children;
  final int crossAxisCellCount;
  final int mainAxisCellCount;

  const ScrollingReportTile({
    super.key,
    required this.title,
    required this.children,
    this.crossAxisCellCount = 2,
    this.mainAxisCellCount = 2,
  });

  @override
  State<ScrollingReportTile> createState() => _ScrollingReportTileState();
}

class _ScrollingReportTileState extends State<ScrollingReportTile> {
  late PageController pageController;
  var currentPage = 1;

  @override
  void initState() {
    super.initState();

    pageController = PageController(initialPage: currentPage - 1);
  }

  @override
  void dispose() {
    pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReportTile(
      mainAxisCellCount: widget.mainAxisCellCount,
      crossAxisCellCount: widget.crossAxisCellCount,
      child: Center(
        child: Column(
          children: [
            widget.title,
            Flexible(
              child: Stack(
                children: [
                  PageView(
                    controller: pageController,
                    children: [
                      for (final child in widget.children)
                        Container(
                          margin: const EdgeInsets.all(8.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade800,
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Expanded(child: child),
                                const Text(''),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => setState(() {
                              if (currentPage > 1) {
                                currentPage--;
                                pageController.animateToPage(
                                  currentPage - 1,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.decelerate,
                                );
                              }
                            }),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            '$currentPage/${widget.children.length}',
                          ),
                          IconButton(
                            onPressed: () => setState(() {
                              if (currentPage < widget.children.length) {
                                currentPage++;
                                pageController.animateToPage(
                                  currentPage - 1,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.decelerate,
                                );
                              }
                            }),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportValue extends StatelessWidget {
  final Widget title;
  final Widget value;
  final Widget? subtext;

  const ReportValue({
    super.key,
    required this.title,
    required this.value,
    this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DefaultTextStyle(
          style: DefaultTextStyle.of(context).style,
          textAlign: TextAlign.center,
          child: title,
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 50,
                      ),
                  child: value,
                ),
                if (subtext case final subtext?)
                  DefaultTextStyle(
                    style: DefaultTextStyle.of(context).style,
                    textAlign: TextAlign.center,
                    child: subtext,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
