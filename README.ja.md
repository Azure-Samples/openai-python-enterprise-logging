# エンタープライズ向けAzure OpenAIアプリ基盤

エンタープライズ向けAzure OpenAIアプリ基盤の参照アーキテクチャのデプロイ方法の詳細を示すリポジトリ。

## ソリューションの主な利点:
*	<b>責任あるAI利用のためのプロンプトと応答監視。</b>  ログ情報には、ユーザーがモデルに送信しているテキストと、モデルから受信されているテキストが含まれます。これにより、モデルが企業環境内およびサービスの承認されたユースケース内で責任を持って使用されるようになります。
*	<b>利用制御とスロットリング制御により、</b> さまざまなユーザグループに対してきめ細かなアクセス制御が可能になります。
*	<b>高可用性構成により、</b> トラフィックが 1 つの Azure OpenAI サービスの制限を超えた場合でも、ユーザー要求が満たされるようにします。
*	<b>高セキュリティ</b>を実現するために、最小特権の原則に従ってAzure Active DirectoryのRBACを活用します。

[![video](assets/video.png)](https://clipchamp.com/watch/WX92A7nDyR4 'link')

## リファレンスアーキテクチャ
![img](/assets/EnterpriseAOAI-Architecture.png)

## 機能

このプロジェクト フレームワークは、次の機能を提供します:

* OpenAI 使用状況メトリックのエンタープライズログ:
   * トークン利用
   * モデル利用
   * プロンプト入力
   * ユーザー統計
   * プロンプト応答
* リージョンのフェールオーバーによるOpenAI サービスの高可用性
* 最新のOpenAIライブラリとの統合
  *  [OpenAI](https://github.com/openai/openai-python/) 
  *  [LangChain](https://python.langchain.com/en/latest/)
  *  [Llama-index](https://gpt-index.readthedocs.io/en/latest/)

## はじめ方

### 前提条件
- [Azure サブスクリプション](https://azure.microsoft.com/en-us/get-started/)
- [Azure OpenAI 利用許可](https://aka.ms/oai/access) 
- 
### インストール
アーティファクトのプロビジョニングは、まず、次に示すソリューションアーティファクトをプロビジョニングします:

-	[Azure OpenAI Cognitive Service]( https://azure.microsoft.com/en-us/products/cognitive-services/openai-service/)
-	[Azure API Management](https://azure.microsoft.com/services/api-management/)
-	[Azure Monitor](https://azure.microsoft.com/services/monitor/)
-	[Azure Application Gateway](https://azure.microsoft.com/services/application-gateway/)
-	[Azure Virtual Network](https://azure.microsoft.com/services/virtual-network/)

### マネージドサービス
-	[Azure Key Vault](https://azure.microsoft.com/services/key-vault/)
-	[Azure Storage](https://azure.microsoft.com/services/storage/)
-	[Azure Active Directory](https://azure.microsoft.com/services/active-directory/)

## 構成

### Azure OpenAI
- まずは、Azure OpenAIのリソースをプロビジョニングします。<b>現在のプライマリリージョンは米国東部であり</b>新しいモデルと容量は他のリージョンよりも先にこの場所でプロビジョニングされることに注意してください。 [リソースのプロビジョニング](https://portal.azure.com/?microsoft_azure_marketplace_ItemHideKey=microsoft_openai_tip#create/Microsoft.CognitiveServicesOpenAI)

- リソースがプロビジョニングされたら、選択したモデルを使用してDeploymentを作成します: [モデルのデプロイ](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/how-to/create-resource?pivots=web-portal#deploy-a-model)

- モデルがデプロイされたら、OpenAI スタジオに遷移して、新しく作成したモデルをスタジオのプレイグラウンドでテストします。 [oai.azure.com/portal](oai.azure.com/portal)


### API Management

- Azure ポータルを使用してプロビジョニングできます :[リソースのプロビジョニング](https://learn.microsoft.com/en-us/azure/api-management/get-started-create-service-instance) 
- API Management サービスがプロビジョニングされたら、サービスの OpenAPI 仕様を使用して OpenAI API レイヤーをインポートできます。
  - [インポート手順](https://learn.microsoft.com/en-us/azure/api-management/import-and-publish#go-to-your-api-management-instance)
  - [APIM - API] ブレードを開き、既存の API の [ インポート ] オプションを選択します。  
  ![img](/assets/apim_config_0.0.png)
  - [ 更新 ] オプションを選択して、API を現在の OpenAI 仕様に更新します。
    - Completions OpenAPI -  https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/preview/2023-03-15-preview/inference.json
  ![img](/assets/apim_config_0.1.png)
- <b>すべての API 操作のために</b>:
  - <b>設定</b> で、OpenAI ライブラリの仕様と一致するように サブスクリプション - <b>ヘッダー名]</b> を "api-key" に設定します。
  ![img](assets/apim-config-apikey.png)
  -  "set-headers" のinbound ruleを構成して、"api-key" ヘッダーパラメーターを OpenAI サービスからの API シークレットキーの値で追加/上書きします。OpenAIキーを見つけるための手順はここにあります: [キーを取得する](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/quickstart?pivots=programming-language-python#retrieve-key-and-endpoint)
  ![img](/assets/apim_config_1.png)
  - デプロイされたOpenAIサービスのエンドポイントにバックエンドサービスを`/openai`として構成し、既存のエンドポイントを必ず上書きしてください。 
    - 例: <b>https://< yourservicename >.openai.azure.com<i>/openai</i></b>
    - [エンドポイントの取得](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/quickstart?pivots=programming-language-python#retrieve-key-and-endpoint)
  ![img](/assets/apim_config_2.png)
  - 診断ログの設定を構成します:
    - Sampling rateを100%に設定します
    - 「Number of payload bytes to log」を最大値に設定します。
  ![img](/assets/apim_config_3.png)

- APIのテスト
  - "デプロイ ID"、"API バージョン"、およびサンプル プロンプトを指定して、エンドポイントをテストします:
    ![img](/assets/apim_config_4.png)

  
#### サブスクリプションのアクセス制御
API Management を使用すると、API プロバイダーは API を不正使用から保護し、さまざまな API 製品レベルの価値を生み出すことができます。API 管理レイヤーを使用して受信要求を調整することは、Azure API 管理の重要な役割です。要求の速度または転送された要求/データの合計を制御することによって。
<br/>APIM レイヤーの構成の詳細: https://learn.microsoft.com/en-us/azure/api-management/api-management-sample-flexible-throttling

### OpenAIのログ記録
- API 管理レイヤーを構成したら、サブスクリプション キー パラメーターをcompletion要求に追加することで、API レイヤーを使用するように既存の OpenAI Python コードを構成できます。 例：
```python
import openai

openai.api_type = "azure"
openai.api_base = "https://xxxxxxxxx.azure-api.net/" # APIM Endpoint
openai.api_version = "2023-03-15-preview"
openai.api_key = "APIM SUBSCRIPTION KEY" #DO NOT USE ACTUAL AZURE OPENAI SERVICE KEY


response = openai.Completion.create(engine="modelname",  
                                    prompt="prompt text", temperature=1,  
                                    max_tokens=200,  top_p=0.5,  
                                    frequency_penalty=0,  
                                    presence_penalty=0,  
                                    stop=None) 

```

</code>

## デモ

- OpenAI 要求が Azure Monitor サービスへのログ記録を開始したら、Log Analytics クエリを使用してサービスの使用状況の分析を開始できます。
  - [Log Analytics チュートリアル](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-tutorial)
- テーブルの名前は  <b>"ApiManagementGatewayLogs"</b>テーブルの名前は 
- <b>BackendResponseBody</b> フィールドには、テキスト補完、トークンおよびモデル情報を含む OpenAI サービスからの json 応答が含まれています。
- IP とモデルによってトークンの使用状況を識別するクエリの例:
```kusto
ApiManagementGatewayLogs
| where OperationId == 'completions_create'
| extend modelkey = substring(parse_json(BackendResponseBody)['model'], 0, indexof(parse_json(BackendResponseBody)['model'], '-', 0, -1, 2))
| extend model = tostring(parse_json(BackendResponseBody)['model'])
| extend prompttokens = parse_json(parse_json(BackendResponseBody)['usage'])['prompt_tokens']
| extend completiontokens = parse_json(parse_json(BackendResponseBody)['usage'])['completion_tokens']
| extend totaltokens = parse_json(parse_json(BackendResponseBody)['usage'])['total_tokens']
| extend ip = CallerIpAddress
| where model !=  ''
| summarize
    sum(todecimal(prompttokens)),
    sum(todecimal(completiontokens)),
    sum(todecimal(totaltokens)),
    avg(todecimal(totaltokens))
    by ip, model
```
![img](/assets/monitor_0.png)
- プロンプトの完了を監視するクエリの例:
```kusto
ApiManagementGatewayLogs
| where OperationId == 'completions_create'
| extend model = tostring(parse_json(BackendResponseBody)['model'])
| extend prompttokens = parse_json(parse_json(BackendResponseBody)['usage'])['prompt_tokens']
| extend prompttext = substring(parse_json(parse_json(BackendResponseBody)['choices'])[0], 0, 100)
```
![img](/assets/monitor_1.png)


