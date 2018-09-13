Pod::Spec.new do |s|
  s.name             = 'MBWebViewModule'
  s.version          = '1.0'
  s.summary          = '封装好的webView'

  #添加第三方依赖

  #QMUI
  s.dependency 'QMUIKit'
  #常用
  s.dependency 'JSONModel'
  s.dependency 'SDWebImage'
  s.dependency 'SDWebImage/GIF'
  s.dependency 'SDWebImage/WebP'
  s.dependency 'AFNetworking'
  s.dependency 'GCDObjC'
  s.dependency 'MJRefresh'
  s.dependency 'Masonry'

  #js交互
  s.dependency 'WebViewJavascriptBridge'
  s.dependency 'NJKWebViewProgress'
  #WebView秒开
  s.dependency 'VasSonic', '3.0.0'

  #异步
  s.dependency 'PromiseKit', '~> 1.7'

  #选照片
  s.dependency 'MBPhotoPicker', '~> 2.2.1'

  #顶部信息提示
  s.dependency 'MBTips'

  #选项目
  s.dependency 'SelectProject'

  #处理并上传照片到七牛
  s.dependency 'UploadImageTool'

  <<-DESC
  APP中封装好的webView容器，方便 js 交互。
  DESC

  s.homepage         = 'https://github.com/titer18/MBWebViewModule'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'titer' => 'zhaohong1991@hotmail.com' }
  s.source           = { :git => 'https://github.com/titer18/MBWebViewModule.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'MBWebViewModule/**/*.{h,m}'
  s.resources    = 'MBWebViewModule/Assets/**'
  s.resources    = 'MBWebViewModule/**/*.xib'
  s.public_header_files = 'MBWebViewModule/**/*.h'

  s.subspec 'NavigatorModule' do |ss|

    #URL跳转
    ss.dependency 'DCURLRouter', '~> 0.81'

    ss.source_files = 'NavigatorModule/**/*.{h,m}'
    ss.resources    = 'NavigatorModule/*.plist'
    ss.public_header_files = 'NavigatorModule/**/*.h'
  end

  s.subspec 'OpenLocationModule' do |ss|
    ss.source_files = 'OpenLocationModule/**/*.{h,m}'
    ss.public_header_files = 'OpenLocationModule/**/*.h'
  end

  s.subspec 'WebPURLProtocol' do |ss|
    ss.dependency 'SDWebImage'
    ss.dependency 'SDWebImage/WebP'

    ss.source_files = 'WebPURLProtocol/**/*.{h,m}'
    ss.public_header_files = 'WebPURLProtocol/**/*.h'
  end

end