# **Dokumen Integrasi E-Smartlink**

**Response Code :**  
00 : Success Create Order  
01 : Request Parameter Error / Validation Error 02 : Data Not Found  
03 : Authorization Failed  
99 : Unknown Error / Invalid Signature

**URL SANDBOX : https://payment-service-sbx.pakar-digital.com**

**Authorization :**

| Type | Value |
| :---- | :---- |
| **Basic** | Basic base64\_encode(**username**:**password**) |

\*gunakan **username** dan **password** yang telah diberikan oleh tim kita

**Request Headers :**

| Key | Value | Requirement |
| :---- | :---- | :---- |
| **Authorization** | Basic base64\_encode(username:password) | mandatory (createOrder dan Inquiry) |
| **Content-Type** | application/json | mandatory (all request) |

1. # **Create Order**

| Method | URL |
| :---- | :---- |
| **POST** | /api/payment/create-order |

**Request:**

| Params | Type Data | Requirement | Detail |
| :---- | :---- | :---- | :---- |
| order\_id  amount description  customer    customer.name     customer.email  customer.phone  customer.address  item item.name        item.amount item.qty  channel  type  expired\_time  payment\_mode payment\_code callback\_url  success\_redirect\_url failed\_redirect\_url return\_url | string int string  object string string    int  (5-15)  string array string int int  array  string  datetime  string string string  string string string | mandatory mandatory optional  mandatory mandatory mandatory   mandatory  optional mandatory mandatory mandatory mandatory  mandatory  mandatory  optional  optional optional mandatory  optional optional optional | Ex : ORDER-0001 Amount \== Item Amount \* Item Qty Deskripsi pembayaran   Nama customer Email customer   Nomor hp customer customer address Nama item  Harga item Jumlah item Channel pembayaran yang telah disediakan oleh tim, ex : \[“VA\_BNI”,”WALLET\_OVO”,”OTC\_I NDOMARET”\]  Type hanya ada “json” dan “payment- page”,  \- “json” akan memberikan json, \- “payment-page” akan memberikan respons berisi url untuk redirect ke halaman kami (support iframe / webview selain channel Credit Card). ISO 8601, ex : 2023-02-22T12:00:00+07:00  only VA CLOSE / OPEN, default value is CLOSE static va number max 6 digitex: “123456”, (VA\_BCA dan VA\_BSI belum mendukung untuk fitur ini)  Url callback untuk menerima response    setelah Pembayaran dilakukan  Requirement akan berubah menjadi **mandatory** jika **type “payment- page”**  Requirement berubah menjadi **mandatory** jika **type “payment- page”** url untuk type payment-page, kembali ke web client ketika tekan tombol back  |

**contoh :** 

| request JSON type:  curl \-L 'https://payment-service-sbx.pakar-digital.com/api/payment/create-order' \-H 'Authorization: Basic base64(username:password)' \-H 'Content-Type: application/json' \-H 'Accept: application/json' \--data-raw '{     "order\_id": "67460824716035",     "amount": 10000,     "description": "test create api di sandbox ",     "customer": {         "name": "John",         "email": "john.doe@gmail.com",         "phone": "089798798686"     },     "item": \[         {             "name": "Pulsa 1k",             "amount": 5000,             "qty": 1         },         {             "name": "Softcase",             "amount": 5000,             "qty": 1         }     \],     "channel": \[         "VA\_CIMB"     \],     "type": "json",     “payment\_mode”: “OPEN”,     "expired\_time": "",     "callback\_url": "https://merchant-url.com",     "success\_redirect\_url": "https://merchant-url.com",     "failed\_redirect\_url": "https://merchant-url.com" }' \================================================= response VA:  {     "status": "success",     "code": 0,     "message": "Success Create Payment",     "data": {         "transaction\_id": "08278c39-9a54-4a23-a9d2-6545f92947d7",         "order\_id": "67460824716035",         "channel": "VA\_CIMB",         "customer": {             "email": "john.doe@gmail.com",             "full\_name": "John",             "phone": "089798798686"         },         "payment\_details": {             "amount": 10000,             "expired\_time": "2023-07-30T13:11:26+07:00",             "transaction\_description": "test create api di sandbox",             "payment\_system": "CLOSED",             "billing\_name": "John",             "payment\_code": "1419003184937237"         },         "item\_details": {             "name": "Pulsa 1k(1x5000), Softcase(1x5000), ",             "amount": 10000,             "qty": 1         }     } } response QRIS:  { 	"status": "success", 	"code": 0, 	"message": "Success Create Payment", 	"data": {     	"transaction\_id": "49cae6dd-d0ad-4e96-a54d-cc2aa4a37a0c",     	"order\_id": "3179490544787",     	"channel": "WALLET\_QRIS",     	"customer": {         	"phone": "089798798686",         	"email": "agung463@gmail.com",         	"full\_name": "agung"     	},     	"payment\_details": {         	"amount": 15000,         	"expired\_time": "2024-01-18T20:46:36+07:00",         	"transaction\_description": "pembelian voucher",         	"qr\_string": "00020101021226610016ID.CO.SHOPEE.WWW01189360091800206059730208206059730303UME51440014ID.CO.QRIS.WWW0215ID20221910517560303UME520453995303360540815000.005802ID5911E-smartlink6014KAB. MOJOKERTO61056135162160512PRA-2672841263046916"     	},     	"item\_details": {         	"name": "Pulsa 1k(1x15000), ",         	"amount": 15000,         	"qty": 1     	} 	} } |
| :---- |
|  |

| Request Payment Page type:  curl \-L 'https://payment-service-sbx.pakar-digital.com/api/payment/create-order' \-H 'Authorization: Basic base64(username:password)' \-H 'Content-Type: application/json' \-H 'Accept: application/json' \--data-raw '{     "order\_id": "3973650819045",     "amount": 10000,     "description": "test create api di sandbox ",     "customer": {         "name": "John",         "email": "john.doe@gmail.com",         "phone": "089798798686"     },     "item": \[         {             "name": "Pulsa 1k",             "amount": 5000,             "qty": 1         },         {             "name": "Softcase",             "amount": 5000,             "qty": 1         }     \],     "channel": \[         "VA\_PERMATA"     \],     "type": "payment-page",     "expired\_time": "",     "callback\_url": "https://merchant-url.com",     "success\_redirect\_url": "https://merchant-url.com",     "failed\_redirect\_url": "https://merchant-url.com" }' \================================================= Response :  {     "status": "success",     "code": 0,     "message": "Success Create Payment",     "data": {         "transaction\_id": "f5988432-e905-4e4e-a2ac-904fd538df2b",         "payment\_url": "https://payment-service-sbx.pakar-digital.com/payment-api/redirect/id/MTgwMg=="     } } |
| :---- |

**Callback:**

| signature (sha256) :  order\_id \+ amount \+ channel \+ transaction\_time \+ email\_credential  {     "status": "success",     "code": 0,     "message": "Order Callback",     "data": {         "transaction\_id": "38e50d6c-f7e4-4cfc-ae3e-da2508aa0e33",         "signature": "9b3e24319c5a1c3a26d869b0270802057e17c4f0f1a26edf0f058ddeb4a3a72f",         "order\_id": "20100198482153",         "channel": "VA\_CIMB",         "payment\_code": "1419003184837714",         "amount": 10000,         "issuer": “CIMB”,         "payment\_mode": “CLOSE”,         "transaction\_time": "2023-07-29T12:29:48+07:00",         "status": "SUCCESS"     } }  |
| ----- |

2. # **Virtual Payment**

   Virtual Payment Hanya dapat digunakan untuk pembayaran via OTC

| Method | URL |
| :---- | :---- |
| **POST** | /api/virtual-payment |

**Request :**

| Params | Type Data | Requirement | Detail |
| :---- | :---- | :---- | :---- |
| payment\_code  approval | string  string | mandatory  mandatory | Payment code didapat dari setelah berhasil create Order via OTC saja  Hanya **SUCCESS** dan **FAILED** |

\* Untuk melakukan simulasi pembayaran sukses bisa menggunakan fitur *force update* yang dalam dashboard.  
\* Untuk EWALLET sementara tidak dapat dilakukan uji coba pembayaran

3. # **Inquiry Order**

| Method | URL |
| :---- | :---- |
| **GET** | /api/payment/inquiry-order/{transaction\_id} |

**Request :**

| Query | Type Data | Requirement | Detail |
| :---- | :---- | :---- | :---- |
| transaction\_id | string | mandatory | Transaction\_id didapatkan setelah berhasil menggenerate pembayaran dari semua channel yang disediakan |

**Response:**

|  {     "status": "success",     "code": 0,     "message": "Success Get Order",     "data": {         "transaction\_id": "d68ba6b2-2922-451d-b6fd-8b6042901593",         "order\_id": "TRX2025052000014",         "amount": 15000,         "description": "Uji Coba Bayar Pajak,",         "status": "PENDING",         "channel": "VA\_BRI",         "payment\_code": "150091204790049785",         "customer": {             "name": "Abdul Wahid",             "email": "trxcustomer@gmail.com",             "phone": "088788888888"         },         "item": \[             {                 "name": "Uji Coba Bayar Pajak",                 "amount": 15000,                 "qty": 1             }         \],         "type": "json",         "issuer": "-",         "callback\_url": "https://cobadapetincallbacktest.free.beeceptor.com",         "success\_redirect\_url": "-",         "failed\_redirect\_url": "-"     } }  |
| :---- |

4. # **Cancel Order**

| Method | URL |
| :---- | :---- |
| **POST** | /api/payment/cancel-order/{transaction\_id} |

**Request :**

| Query | Type Data | Requirement | Detail |
| :---- | :---- | :---- | :---- |
| transaction\_id | string | mandatory | Transaction\_id didapatkan setelah berhasil menggenerate pembayaran dari semua channel yang disediakan |

**Response:**

|  {     "status": "success",     "code": 0,     "message": "Success Cancel Payment",     "data": {         "transaction\_id": "4ddd80d8-4981-42a5-8931-35974a9eb47a",         "order\_id": "TRXL-24061100012",         "amount": 20000,         "description": "VOUCHER",         "status": "CANCELED",         "channel": "VA\_CIMB",         "payment\_code": "1419003185960069",         "customer": {             "name": "CustomerName",             "email": "t.devils240202@gmail.com",             "phone": "-"         },         "item": \[             {                 "name": "Diamond Testing",                 "amount": 10000,                 "qty": 1             },             {                 "name": "Diamond Testing 2",                 "amount": 10000,                 "qty": 1             }         \],         "type": "json",         "issuer": "-",         "callback\_url": "https://cobadapetincallbacktest.free.beeceptor.com",         "success\_redirect\_url": "-",         "failed\_redirect\_url": "-"     } }  |
| :---- |

   **5\. UpdateOrder**

| Method | URL |
| :---- | :---- |
| **PUT** | /api/payment/update-order/{transaction\_id} |

**Request :**

| Query | Type Data | Requirement | Detail |
| :---- | :---- | :---- | :---- |
| amount description payment\_code expired\_time | int string string string | mandatory mandatory mandatory mandatory | Update amount transaction Update description transaction Update VA NUMBER only in channel VA Update Expired Date Transaction |

**\*Updates can only be made when the transaction status is PENDING and the channel is VA\_BRI.**  
**Response:**

|  {     "status": "success",     "code": 0,     "message": "Success Update Payment",     "data": {         "transaction\_id": "e9769ef6-dd14-4379-b57d-93b8b4298e71",         "order\_id": "STTRX-24082500992",         "amount": 20000,         "description": "update test descnya",         "status": "PENDING",         "channel": "VA\_BRI",         "payment\_code": "22000000990099991",         "customer": {             "name": "CustomerName",             "email": "cutomer.mail@gmail.com",             "phone": "089602814567"         },         "item": \[             {                 "name": "Diamond Testing",                 "amount": 10000,                 "qty": 1             },             {                 "name": "Diamond Testing 2",                 "amount": 10000,                 "qty": 1             }         \],         "type": "json",         "issuer": "-",         "callback\_url": "https://cobadapetincallbacktest.free.beeceptor.com",         "expired\_time": "2024-08-26T07:30:00+07:00",         "success\_redirect\_url": "-",         "failed\_redirect\_url": "-"     } } |
| :---- |

