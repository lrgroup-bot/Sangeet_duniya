#!/usr/bin/env python3
from __future__ import annotations
import argparse, base64, json, secrets, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

APP='LRs Sangeet_Duniya'

def iso(ms=None):
    if ms is None: ms=int(time.time()*1000)
    return time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(ms/1000))

class Store:
    def __init__(self, root):
        self.root=Path(root); self.root.mkdir(parents=True, exist_ok=True)
        self.cfg=self.root/'config.json'; self.tokens=self.root/'tokens.json'; self.users=self.root/'users.json'
        self._ensure()
    def _read(self,p,default):
        try: return json.loads(p.read_text(encoding='utf-8'))
        except Exception: return default
    def _write(self,p,v):
        tmp=p.with_suffix(p.suffix+'.tmp'); tmp.write_text(json.dumps(v,indent=2),encoding='utf-8'); tmp.replace(p)
    def _ensure(self):
        if not self.cfg.exists(): self._write(self.cfg,{'user_key':secrets.token_urlsafe(32),'admin_key':secrets.token_urlsafe(40),'created_at':iso()})
        if not self.tokens.exists(): self._write(self.tokens,{'tokens':[]})
        if not self.users.exists(): self._write(self.users,{'users':[]})
    @property
    def user_key(self): return str(self._read(self.cfg,{}).get('user_key',''))
    @property
    def admin_key(self): return str(self._read(self.cfg,{}).get('admin_key',''))
    def get_tokens(self): return self._read(self.tokens,{'tokens':[]}).get('tokens',[])
    def set_tokens(self,v): self._write(self.tokens,{'tokens':v})
    def get_users(self): return self._read(self.users,{'users':[]}).get('users',[])
    def save_user(self,u):
        items=self.get_users(); phone=u['phone']
        for i,x in enumerate(items):
            if x.get('phone')==phone: u['id']=x.get('id',u['id']); items[i]=u; break
        else: items.append(u)
        self._write(self.users,{'users':items})

def equal(a,b):
    if len(a)!=len(b): return False
    x=0
    for aa,bb in zip(a.encode(),b.encode()): x |= aa ^ bb
    return x==0

def token_payload(token):
    p=token.strip().split('.')
    if len(p)!=3 or p[0]!='LRS1': return None
    try:
        raw=base64.urlsafe_b64decode(p[1]+'='*(-len(p[1])%4))
        d=json.loads(raw.decode())
        if not isinstance(d,dict) or d.get('v')!=1: return None
        exp=int(d.get('expires',0)); now=int(time.time()*1000)
        if exp and now>=exp: return None
        return {'plan':str(d.get('plan','')),'issued':int(d.get('issued',0)),'expires':exp,'phone':str(d.get('phone',''))}
    except Exception: return None

class Handler(BaseHTTPRequestHandler):
    server_version='LRS-PC-Admin/1.0'
    def log_message(self,fmt,*args): print('[LRS-PC]',fmt%args)
    @property
    def store(self): return self.server.store
    def request_path(self): return urlparse(self.path_raw).path or '/'
    def key(self): return parse_qs(urlparse(self.path_raw).query).get('key',[''])[0]
    def json(self,status,payload):
        data=b'' if payload is None else json.dumps(payload).encode()
        self.send_response(status); self.send_header('Content-Type','application/json'); self.send_header('Cache-Control','no-store'); self.send_header('Access-Control-Allow-Origin','*'); self.send_header('Access-Control-Allow-Methods','GET,POST,OPTIONS'); self.send_header('Access-Control-Allow-Headers','content-type'); self.send_header('Content-Length',str(len(data))); self.end_headers()
        if data: self.wfile.write(data)
    def read(self):
        try: return json.loads(self.rfile.read(int(self.headers.get('Content-Length','0'))).decode())
        except Exception: return None
    def user_ok(self): return equal(self.key(),self.store.user_key)
    def admin_ok(self): return equal(self.key(),self.store.admin_key)
    def do_OPTIONS(self): self.path_raw=self.path; self.json(204,None)
    def do_GET(self):
        self.path_raw=self.path; p=self.request_path()
        if p=='/health': return self.json(200,{'ok':True,'app':APP,'server':'PC'})
        if p=='/connect':
            if not self.user_ok(): return self.json(401,{'ok':False,'error':'User key required.'})
            return self.json(200,{'ok':True,'message':'Connected to PC admin server.'})
        if p=='/users':
            if not self.admin_ok(): return self.json(401,{'ok':False,'error':'Admin key required.'})
            return self.json(200,{'ok':True,'users':self.store.get_users()})
        if p=='/admin':
            if not self.admin_ok(): return self.json(401,{'ok':False,'error':'Admin key required.'})
            return self.json(200,{'ok':True,'users':len(self.store.get_users()),'tokens':len(self.store.get_tokens())})
        return self.json(404,{'ok':False,'error':'Not found.'})
    def do_POST(self):
        self.path_raw=self.path; p=self.request_path(); body=self.read()
        if p=='/tokens':
            if not self.admin_ok(): return self.json(401,{'ok':False,'error':'Admin key required.'})
            raw=(body or {}).get('tokens',[])
            out=[]
            for token in raw if isinstance(raw,list) else []:
                t=str(token).strip(); info=token_payload(t)
                if info: out.append({'token':t,**info,'syncedAt':iso()})
            self.store.set_tokens(out); return self.json(200,{'ok':True,'synced':len(out)})
        if p=='/register':
            if not self.user_ok(): return self.json(401,{'ok':False,'error':'User key required.'})
            b=body or {}; name=str(b.get('name','')).strip(); phone=str(b.get('phone','')).strip(); token=str(b.get('token','')).strip()
            if not name or len(phone)<7 or not token: return self.json(400,{'ok':False,'error':'Name, phone and token are required.'})
            if not any(x.get('token')==token for x in self.store.get_tokens()): return self.json(403,{'ok':False,'error':'Token not synced to PC yet.'})
            info=token_payload(token)
            if not info: return self.json(403,{'ok':False,'error':'Token is invalid or expired.'})
            if info['phone'] and info['phone']!=phone: return self.json(403,{'ok':False,'error':'Token is bound to a different phone.'})
            u={'id':str(int(time.time()*1000000)),'name':name,'phone':phone,'plan':info['plan'],'issued':iso(info['issued']),'activated':iso(),'expires':iso(info['expires']) if info['expires'] else None,'token':token}
            self.store.save_user(u); return self.json(200,{'ok':True,**u})
        return self.json(404,{'ok':False,'error':'Not found.'})

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--host',default='127.0.0.1'); ap.add_argument('--port',type=int,default=40426); ap.add_argument('--data-dir',default='.lrs-admin-data'); a=ap.parse_args()
    s=Store(a.data_dir); httpd=ThreadingHTTPServer((a.host,a.port),Handler); httpd.store=s
    print('\nLRs Sangeet_Duniya PC Admin Server')
    print('Local:',f'http://{a.host}:{a.port}')
    print('Data :',Path(a.data_dir).resolve())
    print('\nUSER KEY (safe to share with app users):\n'+s.user_key)
    print('\nADMIN KEY (keep private; put only in the admin phone):\n'+s.admin_key)
    print('\nThen expose this port with Tailscale Serve or Funnel.')
    print('Check existing config first: tailscale serve status && tailscale funnel status')
    httpd.serve_forever()

if __name__=='__main__': main()