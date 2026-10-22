// 导入AI服务（调DeepSeek API的函数、返回类型、生成菜单文本的函数）
import { chatWithAi, AiResponse, buildMenuContext } from '../../services/AiService';
// 导入店铺数据类型
import { ShopItem } from '../../services/Types';

// 聊天消息的结构：role决定是谁发的，content是消息内容
interface AiChatMsg {
  role: 'user' | 'assistant';
  content: string;
}

// 聊天界面的颜色配置
interface ColorConfig {
  PAGE: string;
  SURFACE: string;
  PRIMARY: string;
  TEXT: string;
  SUB_TEXT: string;
  LINE: string;
}

// 定义具体颜色值（十六进制颜色码）
const COLORS: ColorConfig = {
  PAGE: '#F7F8F5',    // 页面背景色（浅灰白）
  SURFACE: '#FFFFFF', // 卡片/组件背景色（纯白）
  PRIMARY: '#F97316', // 主题色（橙色）
  TEXT: '#1F2933',    // 主文字色（深灰）
  SUB_TEXT: '#6B7280',// 辅助文字色（中灰）
  LINE: '#E9EDF2'     // 边框/分割线色（浅灰）
};

@Component
export struct AiChatPage {
  // @Link：从父页面（Index.ets）传过来的店铺列表数据
  @Link shops: ShopItem[];
  // @State：聊天消息列表，数据变化时界面自动更新
  @State chatMessages: AiChatMsg[] = [];
  // 是否正在等待AI回复（控制加载动画显示/隐藏）
  @State isLoading: boolean = false;
  // 输入框当前文字
  @State inputText: string = '';
  // 滚动控制器，用于自动滚到聊天列表底部
  private scroller: Scroller = new Scroller();
  // 快捷提问的4个建议问题
  private suggestions: string[] = [
    '\u4eca\u5929\u4e2d\u5348\u5403\u4ec0\u4e48\u597d\uff1f',
    '\u63a8\u8350\u4e00\u4e2a\u4fbf\u5b9c\u53c8\u597d\u5403\u7684\u5957\u9910',
    '\u6709\u4ec0\u4e48\u8fa3\u7684\u83dc\u63a8\u8350\u5417\uff1f',
    '\u7ed9\u6211\u63a8\u8350\u4e00\u4efd15\u5143\u4ee5\u5185\u7684\u5348\u9910'
  ];

  // 组件初始化时自动执行：在聊天列表中加入AI的欢迎消息
  aboutToAppear(): void {
    this.chatMessages.push({
      role: 'assistant',
      content: '\u4f60\u597d\u54df\uff01\u6211\u662f\u5c0f\u996d\u56e2~ \ud83c\udf5a\ud83e\udd16\n\u6211\u53ef\u4ee5\u5e2e\u4f60\u63a8\u8350\u83dc\u54c1\u3001\u89e3\u7b54\u83dc\u5355\u95ee\u9898\uff01\ud83c\udfaf\n\u6709\u4ec0\u4e48\u60f3\u5403\u7684\u5417\uff1f\ud83d\ude0a'
    });
  }

  // 主构建函数：从上到下排列四个UI模块
  build() {
    Column() {
      // ① 标题栏："AI 点餐助手"
      this.buildHeader()
      // ② 如果还没开始聊天（只有欢迎消息），显示快捷问题
      if (this.chatMessages.length <= 1) {
        this.buildSuggestions()
      }
      // ③ 聊天记录列表（可滚动）
      this.buildChatList()
      // ④ 底部输入框 + 发送按钮
      this.buildInputBar()
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
  }

  // 标题栏：显示"AI 点餐助手"
  @Builder
  buildHeader() {
    Row() {
      Text('AI \u70b9\u9910\u52a9\u624b')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 10 })
    .backgroundColor(COLORS.SURFACE)
    .border({ width: { bottom: 1 }, color: COLORS.LINE })
  }

  // 快捷提问区：显示4个建议问题，点击后直接发送
  @Builder
  buildSuggestions() {
    Column({ space: 8 }) {
      Text('\u8bd5\u8bd5\u95ee\u8fd9\u4e9b\uff1a')
        .fontSize(13)
        .fontColor(COLORS.SUB_TEXT)
        .width('100%')

      ForEach(this.suggestions, (s: string, idx: number) => {
        Text(s)
          .fontSize(14)
          .fontColor(COLORS.PRIMARY)
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          .backgroundColor('#EBF5FF')
          .borderRadius(18)
          .onClick(() => {
            this.sendMessage(s);
          })
      }, (s: string, idx: number) => idx.toString())
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 8 })
  }

  // 聊天记录列表：可滚动区域，显示所有消息气泡
  @Builder
  buildChatList() {
    // Scroll = 可滚动的容器
    Scroll(this.scroller) {
      Column({ space: 12 }) {
        // 如果正在等待AI回复，显示加载动画
        if (this.isLoading) {
          Row() {
            // 鸿蒙的旋转加载图标
            LoadingProgress()
              .width(24)
              .height(24)
              .color(COLORS.PRIMARY)
            // "小饭团正在思考..." 文字
            Text('\u5c0f\u996d\u56e2\u6b63\u5728\u601d\u8003...')
              .fontSize(13)
              .fontColor(COLORS.SUB_TEXT)
              .margin({ left: 8 })
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .alignItems(VerticalAlign.Top)
        }

        // 遍历所有聊天消息，根据role显示不同的气泡样式
        ForEach(this.chatMessages, (msg: AiChatMsg, index: number) => {
          if (msg.role === 'user') {
            this.UserBubble(msg.content)
          } else {
            this.AiBubble(msg.content)
          }
        }, (msg: AiChatMsg, index: number) => index.toString())
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor(COLORS.PAGE)
  }

  // 底部输入栏：输入框 + 发送按钮
  @Builder
  buildInputBar() {
    Row({ space: 8 }) {
      // 文本输入框，placeholder是灰色提示文字
      TextInput({ placeholder: '\u8f93\u5165\u4f60\u60f3\u5403\u7684...', text: this.inputText })
        .height(44)
        .layoutWeight(1)
        .fontSize(15)
        .backgroundColor('#F8FAFC')
        .borderRadius(22)
        .padding({ left: 16, right: 16 })
        .border({ width: 1, color: COLORS.LINE })
        .placeholderColor(COLORS.SUB_TEXT)
        // 输入内容变化时更新inputText
        .onChange((value: string) => {
          this.inputText = value;
        })

      // 发送按钮
      Button() {
        Text('\u53d1\u9001')
          .fontSize(15)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
      }
      .width(60)
      .height(44)
      .backgroundColor(COLORS.PRIMARY)
      .borderRadius(22)
      // 只有输入框有内容且不在加载中时，按钮才可点击
      .enabled(this.inputText.trim().length > 0 && !this.isLoading)
      .onClick(() => {
        // 点击发送按钮，调用sendMessage发送消息
        this.sendMessage(this.inputText);
      })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 12 })
    .backgroundColor(COLORS.SURFACE)
    .border({ width: { top: 1 }, color: COLORS.LINE })
  }

  // 核心发送函数：把用户消息发给AI，收到回复后显示
  private sendMessage(text: string): void {
    // 去掉首尾空格
    const content: string = text.trim();
    // 如果消息为空或正在加载，不执行
    if (content.length === 0 || this.isLoading) {
      return;
    }

    // 将用户消息加入聊天列表
    this.chatMessages.push({ role: 'user', content: content });
    // 清空输入框
    this.inputText = '';
    // 显示加载动画
    this.isLoading = true;

    // 保存this引用，因为在异步回调里this会变化
    const self = this;
    // 延迟50ms后自动滚动到底部，让用户看到刚发的消息
    setTimeout(() => {
      self.scroller.scrollTo({ xOffset: 0, yOffset: self.chatMessages.length * 300, animation: { duration: 200 } });
    }, 50);

    // 生成菜单文本：把所有店铺和菜品转成一段文字
    const menuContext: string = buildMenuContext(this.shops);
    // 调用DeepSeek API：传入用户消息和菜单上下文
    chatWithAi(content, menuContext).then((response: AiResponse) => {
      // 请求成功：关闭加载动画
      self.isLoading = false;
      // 将AI回复加入聊天列表
      self.chatMessages.push({ role: 'assistant', content: response.message });
      // 延迟100ms后自动滚动到底部，让用户看到AI回复
      setTimeout(() => {
        self.scroller.scrollTo({ xOffset: 0, yOffset: self.chatMessages.length * 300, animation: { duration: 300 } });
      }, 100);
    }).catch(() => {
      // 请求失败：关闭加载动画，显示兜底错误提示
      self.isLoading = false;
      self.chatMessages.push({
        role: 'assistant',
        // "抱歉，小饭团暂时无法回答，请稍后再试~"
        content: '\u62b1\u6b49\uff0c\u5c0f\u996d\u56e2\u6682\u65f6\u65e0\u6cd5\u56de\u7b54\uff0c\u8bf7\u7a0d\u540e\u518d\u8bd5~'
      });
    });
  }

  // 用户消息气泡：橙色背景，靠右显示，右下角尖角
  @Builder
  UserBubble(content: string) {
    Row() {
      // 左边空白占位，使气泡靠右
      Column()
        .layoutWeight(1)

      Column() {
        Text(content)
          .fontSize(15)
          .fontColor('#FFFFFF')
          .lineHeight(22)
      }
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor(COLORS.PRIMARY)
      .borderRadius({ topLeft: 16, topRight: 16, bottomLeft: 16, bottomRight: 4 })
      // 气泡宽度不超过屏幕的70%
      .constraintSize({ maxWidth: '70%' })
    }
    .width('100%')
    .margin({ top: 4 })
    .alignItems(VerticalAlign.Top)
  }

  // AI消息气泡：白色背景，靠左显示，左上角尖角
  @Builder
  AiBubble(content: string) {
    Row() {
      Column() {
        Text(content)
          .fontSize(15)
          .fontColor(COLORS.TEXT)
          .lineHeight(22)
      }
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor(COLORS.SURFACE)
      .borderRadius({ topLeft: 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })
      // 气泡宽度不超过屏幕的70%
      .constraintSize({ maxWidth: '70%' })
      // 白色边框
      .border({ width: 1, color: COLORS.LINE })
    }
    .width('100%')
    .margin({ top: 4 })
    .alignItems(VerticalAlign.Top)
  }
}
