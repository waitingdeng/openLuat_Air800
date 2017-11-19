module(...,package.seeall)
require"qrcode"
require"string"

WIDTH,HEIGHT,BPP = disp.getlcdinfo()
--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������testǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("test",...)
end

require"misc"
require"mqtt"
require"common"
module(...,package.seeall)

local ssub,schar,smatch,sbyte,slen = string.sub,string.char,string.match,string.byte,string.len
--����ʱ���Լ��ķ�����
local PROT,ADDR,PORT = "TCP","lbsmqtt.airm2m.com",1883
local mqttclient


--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������testǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("test",...)
end

local qos0cnt,qos1cnt = 1,1

--[[
��������pubqos0testsndcb
����  ��������1��qosΪ0����Ϣ�����ͽ���Ļص�����
����  ��
		usertag������mqttclient:publishʱ�����usertag
		result��true��ʾ���ͳɹ���false����nil����ʧ��
����ֵ����
]]
local function pubqos0testsndcb(usertag,result)
	print("pubqos0testsndcb",usertag,result)
	sys.timer_start(pubqos0test,10000)
	qos0cnt = qos0cnt+1
end

--[[
��������pubqos0test
����  ������1��qosΪ0����Ϣ
����  ����
����ֵ����
]]
function pubqos0test()
	--ע�⣺�ڴ˴��Լ�ȥ����payload�����ݱ��룬mqtt���в����payload���������κα���ת��
  mqttclient:publish("/v1/device/"..misc.getimei().."/qos0topic","qos0data",0,pubqos0testsndcb,"publish0test_"..qos0cnt) --��mqtt�����е�46��
end



--[[
��������subackcb
����  ��MQTT SUBSCRIBE֮���յ�SUBACK�Ļص�����
����  ��
		usertag������mqttclient:subscribeʱ�����usertag
		result��true��ʾ���ĳɹ���false����nil��ʾʧ��
����ֵ����
]]
local function subackcb(usertag,result)
	print("subackcb",usertag,result)
end

--[[
��������rcvmessage
����  ���յ�PUBLISH��Ϣʱ�Ļص�����
����  ��
		topic����Ϣ���⣨gb2312���룩
		payload����Ϣ���أ�ԭʼ���룬�յ���payload��ʲô���ݣ�����ʲô���ݣ�û�����κα���ת����
		qos����Ϣ�����ȼ�
����ֵ����
]]
local function rcvmessagecb(topic,payload,qos)
	print("rcvmessagecb",topic,payload,qos)
	local buf,w,h,isfix = qrcode.create(payload,WIDTH,HEIGHT)
	print(buf,#buf, w,h,isfix)
	disp.setbkcolor(0xffff)
	disp.clear()
	qrcode.display(buf,w,h,(WIDTH - w)/2,(HEIGHT - h)/2,0)
	disp.update()
end

--[[
��������discb
����  ��MQTT���ӶϿ���Ļص�
����  ����		
����ֵ����
]]
local function discb()
	print("discb")
	--20������½���MQTT����
	sys.timer_start(connect,20000)
end

--[[
��������disconnect
����  ���Ͽ�MQTT����
����  ����		
����ֵ����
]]
local function disconnect()
	mqttclient:disconnect(discb)
end

--[[
��������connectedcb
����  ��MQTT CONNECT�ɹ��ص�����
����  ����		
����ֵ����
]]
local function connectedcb()
	print("connectedcb")
	--��������
  mqttclient:subscribe({{topic="/v1/device/"..misc.getimei().."/event0",qos=0}}, subackcb, "subscribetest")   --��mqtt�����е�130��  
	--ע���¼��Ļص�������MESSAGE�¼���ʾ�յ���PUBLISH��Ϣ
	mqttclient:regevtcb({MESSAGE=rcvmessagecb})
	--����һ��qosΪ0����Ϣ
	pubqos0test()
	--20��������Ͽ�MQTT����
	--sys.timer_start(disconnect,20000)
end

--[[
��������connecterrcb
����  ��MQTT CONNECTʧ�ܻص�����
����  ��
		r��ʧ��ԭ��ֵ
			1��Connection Refused: unacceptable protocol version
			2��Connection Refused: identifier rejected
			3��Connection Refused: server unavailable
			4��Connection Refused: bad user name or password
			5��Connection Refused: not authorized
����ֵ����
]]
local function connecterrcb(r)
	print("connecterrcb",r)
end

--[[
��������sckerrcb
����  ��SOCKET�쳣�ص�������ע�⣺�˴��ǻָ��쳣��һ�ַ�ʽ<�������ģʽ������Ӻ��˳�����ģʽ>������޷������Լ������󣬿��Լ������쳣������
����  ��
		r��string���ͣ�ʧ��ԭ��ֵ
			CONNECT��mqtt�ڲ���socketһֱ����ʧ�ܣ����ٳ����Զ�����
			SVRNODATA��mqtt�ڲ���3��KEEP ALIVEʱ��+����ӣ��ն˺ͷ�����û���κ�����ͨ�ţ�����Ϊ����ͨ���쳣
����ֵ����
]]
local function sckerrcb(r)
	print("sckerrcb",r)
	misc.setflymode(true)
	sys.timer_start(misc.setflymode,30000,false)
end

function connect()
	--����mqtt������
	--mqtt lib�У����socket�����쳣��Ĭ�ϻ��Զ���������
	--ע��sckerrcb�������������ע�͵���sckerrcb����mqtt lib��socket�����쳣ʱ�������Զ��������������ǵ���sckerrcb����
	mqttclient:connect("openluat",240,"luat","luat",connectedcb,connecterrcb--[[,sckerrcb]])
end

local function statustest()
	print("statustest",mqttclient:getstatus())
end

--[[
��������imeirdy
����  ��IMEI��ȡ�ɹ����ɹ��󣬲�ȥ����mqtt client�����ӷ���������Ϊ�õ���IMEI��
����  ����		
����ֵ����
]]
local function imeirdy()
	--����һ��mqtt client��Ĭ��ʹ�õ�MQTTЭ��汾��3.1�����Ҫʹ��3.1.1���������ע��--[[,"3.1.1"]]����
	mqttclient = mqtt.create(PROT,ADDR,PORT--[[,"3.1.1"]])
	--������������,�������Ҫ��������һ�д��룬���Ҹ����Լ����������will����
	--mqttclient:configwill(1,0,0,"/willtopic","will payload")
	--����clean session��־���������Ҫ��������һ�д��룬���Ҹ����Լ�����������cleansession����������ã�Ĭ��Ϊ1
	--mqttclient:setcleansession(0)
	--��ѯclient״̬����
	--sys.timer_loop_start(statustest,1000)
	connect()
end

local procer =
{
	IMEI_READY = imeirdy,
}
--ע����Ϣ�Ĵ�������
sys.regapp(procer)