// 导入鸿蒙系统网络请求模块（用于调用DeepSeek API）
import { http } from '@kit.NetworkKit';
// 导入店铺和菜品的数据类型
import { ShopItem, FoodItem } from './Types';

import { API_KEY, DEEPSEEK_API_URL } from './Secrets';

// 聊天消息的数据结构：role决定谁发的消息，content是消息内容
export interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

// App内部统一使用的AI回复格式：success标记成功/失败，message是回复内容
export interface AiResponse {
  success: boolean;
  message: string;
}

// DeepSeek API返回数据中的"一条回复"结构
interface DeepSeekChoice {
  message: DeepSeekMessage;
}

// DeepSeek返回的AI消息内容
interface DeepSeekMessage {
  content: string;
}

// DeepSeek API的完整返回数据结构
interface DeepSeekResponse {
  choices: DeepSeekChoice[];
}

// 把店铺和菜品数据整理成一段可读的文本，作为AI的"上下文"
export function buildMenuContext(shops: ShopItem[]): string {
  let context: string = '';
  // 遍历每个店铺
  for (const shop of shops) {
    // 拼接店铺信息：店名、评分、月销量
    context += '\u3010\u5e97\u94fa\u3011' + shop.name + '\uff08\u8bc4\u5206\uff1a' + shop.score + '\uff0c\u6708\u552e\uff1a' + shop.monthly + '\uff09\n';
    // 按分类（category）将菜品分组
    const categories: Record<string, FoodItem[]> = {};
    for (const food of shop.foods) {
      if (!categories[food.category]) {
        categories[food.category] = [];
      }
      categories[food.category].push(food);
    }
    // 遍历每个分类，拼接分类名和菜品名+价格
    const catList: string[] = Object.keys(categories);
    for (let ci = 0; ci < catList.length; ci++) {
      const cat: string = catList[ci];
      context += '  ' + cat + '\uff1a';
      context += categories[cat].map(f => f.name + '\uff08\u00a5' + f.price + '\uff09').join('\u3001');
      context += '\n';
    }
    context += '\n';
  }
  return context;
}

// 核心函数：向DeepSeek发送聊天请求，返回AI回复
export async function chatWithAi(userMessage: string, menuContext: string): Promise<AiResponse> {
  try {
    // 构造系统提示词：告诉AI它的身份、任务、可用的菜单数据
    const systemPrompt: string =
      '\u4f60\u662f\u4e00\u4e2a\u6821\u56ed\u70b9\u9910\u52a9\u624b\uff0c\u4f60\u7684\u540d\u5b57\u53eb\u5c0f\u996d\u56e2\ud83c\udf5a\u3002\u8bf7\u7528\u4e2d\u6587\u56de\u590d\uff0c\u8bed\u6c14\u4eb2\u5207\u53cb\u597d\uff0c\u53ef\u4ee5\u52a0\u4e00\u4e9b\u8868\u60c5\u5305\u2601\ufe0f\u3002' +
      '\u4f60\u53ef\u4ee5\u5e2e\u52a9\u7528\u6237\u63a8\u8350\u83dc\u54c1\u3001\u89e3\u7b54\u83dc\u5355\u95ee\u9898\u3001\u63d0\u4f9b\u70b9\u9910\u5efa\u8bae\u3002\u4ee5\u4e0b\u662f\u5f53\u524d\u53ef\u70b9\u7684\u83dc\u5355\u4fe1\u606f\uff1a\n' +
      menuContext +
      '\n\u8bf7\u6839\u636e\u7528\u6237\u9700\u6c42\u63a8\u8350\u83dc\u54c1\u6216\u56de\u7b54\u76f8\u5173\u95ee\u9898\u3002\u56de\u590d\u7b80\u6d01\u660e\u4e86\uff0c\u63a8\u8350\u65f6\u7ed9\u51fa\u5177\u4f53\u83dc\u54c1\u540d\u79f0\u3002';

    // 构建要发给DeepSeek的消息数组：系统指令 + 用户问题
    const messages: ChatMessage[] = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userMessage }
    ];

    // 创建HTTP请求客户端
    const httpRequest = http.createHttp();
    // 发送POST请求到DeepSeek API，并等待返回
    const response = await httpRequest.request(
      DEEPSEEK_API_URL,
      {
        method: http.RequestMethod.POST,          // POST方式请求
        header: {
          'Content-Type': 'application/json',     // 发送JSON格式数据
          'Authorization': 'Bearer ' + API_KEY    // 携带API Key进行身份认证
        },
        extraData: JSON.stringify({
          model: 'deepseek-chat',                 // 使用DeepSeek的聊天模型
          messages: messages,                     // 对话消息
          temperature: 0.7,                       // 回复的随机性（0-1，值越大越有创意）
          max_tokens: 500                         // 回复的最大字数
        }),
        expectDataType: http.HttpDataType.OBJECT  // 期望返回JSON对象格式
      }
    );

    // 请求完成后销毁HTTP客户端，释放资源
    httpRequest.destroy();

    // 如果HTTP状态码为200（请求成功）
    if (response.responseCode === 200) {
      const data = response.result as DeepSeekResponse;
      // 确保有回复内容
      if (data.choices && data.choices.length > 0) {
        return {
          success: true,
          message: data.choices[0].message.content   // 取第一条AI回复
        };
      }
      return { success: false, message: '\u65e0\u6cd5\u83b7\u53d6\u56de\u590d' };
    }
    // 请求失败，返回HTTP状态码
    return { success: false, message: '\u8bf7\u6c42\u5931\u8d25\uff0c\u72b6\u6001\u7801\uff1a' + response.responseCode };
  } catch (error) {
    // 网络异常或API报错时，返回网络错误信息
    return { success: false, message: 'NetworkErr' };
  }
}

