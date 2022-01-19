import 'package:flutter/material.dart';
import 'package:kite/dao/library/book_search.dart';
import 'package:kite/dao/library/holding_preview.dart';
import 'package:kite/dao/library/image_search.dart';
import 'package:kite/global/session_pool.dart';
import 'package:kite/page/library/component/search_result_item.dart';
import 'package:kite/service/library.dart';
import 'package:kite/service/library/holding_preview.dart';
import 'package:kite/util/flash.dart';
import 'package:kite/util/library/search.dart';
import 'package:kite/util/logger.dart';

import '../book_info.dart';

class BookSearchResultWidget extends StatefulWidget {
  /// 要搜索的关键字
  final String keyword;

  /// 图书搜索服务
  final BookSearchDao bookSearchDao = BookSearchService(SessionPool.librarySession);

  /// 图书图片搜索服务
  final BookImageSearchDao bookImageSearchDao = BookImageSearchService(SessionPool.librarySession);

  /// 馆藏检索服务
  final HoldingPreviewDao holdingPreviewDao = HoldingPreviewService(SessionPool.librarySession);

  final KeyClickCallback? requestQueryKeyCallback;
  BookSearchResultWidget(this.keyword, {Key? key, this.requestQueryKeyCallback}) : super(key: key);

  @override
  _BookSearchResultWidgetState createState() => _BookSearchResultWidgetState();
}

class _BookSearchResultWidgetState extends State<BookSearchResultWidget> {
  /// 滚动控制器，用于监测滚动到底部，触发自动加载
  final _scrollController = ScrollController();

  /// 每页加载的最大长度
  static const sizePerPage = 30;

  // 本次搜索产生的搜索信息
  var useTime = 0.0;
  var searchResultCount = 0;
  var currentPage = 1;
  var totalPage = 10;

  /// 最终前端展示的数据
  List<BookImageHolding> dataList = [];

  /// 是否处于加载状态
  bool isLoading = false;

  /// 是否是成功加载第一页
  bool firstPageLoaded = false;

  /// 获得搜索结果
  Future<List<BookImageHolding>> _get(int rows, int page) async {
    final searchResult = await widget.bookSearchDao.search(
      keyword: widget.keyword,
      rows: rows,
      page: page,
    );

    // 页数越界
    if (searchResult.currentPage > totalPage) {
      return [];
    }
    useTime = searchResult.useTime;
    searchResultCount = searchResult.resultCount;
    currentPage = searchResult.currentPage;
    totalPage = searchResult.totalPages;

    Log.info(searchResult);
    return await BookImageHolding.simpleQuery(
      widget.bookImageSearchDao,
      widget.holdingPreviewDao,
      searchResult.books,
    );
  }

  /// 用于第一次获取数据
  Future<void> getData() async {
    isLoading = true;
    try {
      final firstPage = await _get(sizePerPage, currentPage);
      setState(() {
        firstPageLoaded = true;
        isLoading = false;
        dataList = firstPage;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 用于后续每次触发加载更多
  Future<void> getMore() async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });
      showBasicFlash(
          context,
          Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(
                width: 15,
              ),
              Text('正在加载更多结果')
            ],
          ),
          duration: const Duration(seconds: 3));
      try {
        final nextPage = await _get(sizePerPage, currentPage + 1);
        if (nextPage.isNotEmpty) {
          setState(() {
            dataList.addAll(nextPage);
            isLoading = false;
          });
        } else {
          showBasicFlash(context, const Text('找不到更多了'));
          isLoading = false;
        }
      } catch (e) {
        showBasicFlash(context, const Text('网络异常，再试一次'));
        isLoading = false;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Log.info('页面滑动到底部');
        getMore();
      }
    });
  }

  Widget buildListView() {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        return Column(children: [
          Container(
            child: InkWell(
              child: BookItemWidget(
                dataList[index],
                onAuthorTap: widget.requestQueryKeyCallback,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (BuildContext context) {
                    return BookInfoPage(dataList[index]);
                  }),
                );
              },
            ),
            padding: const EdgeInsets.fromLTRB(10, 1, 10, 1),
          ),
          const Divider(color: Colors.black),
        ]);
      },
      itemCount: dataList.length,
      controller: _scrollController,
    );
  }

  @override
  Widget build(BuildContext context) {
    Log.info('初始化列表');
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('总结果数: $searchResultCount  用时: $useTime  已加载: $currentPage/$totalPage'),
        Expanded(
          child: firstPageLoaded
              ? buildListView()
              : const Center(
                  child: CircularProgressIndicator(),
                ),
        ),
      ],
    );
  }
}