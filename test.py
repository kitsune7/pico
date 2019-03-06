import requests
import pprint

pp = pprint.PrettyPrinter(indent=2)

def pico_uri(path, eci='FURVFiVsxVCZg44km1xbpR'):
    return 'http://localhost:8080/sky/event/' + eci + '/' + path

def view_test_data():
    r = requests.get(pico_uri('python/manage/view_test_data'))
    pp.pprint(r.json()['directives'])

def new_sensor(id):
    payload = {
        'section_id': id
    }
    r = requests.get(pico_uri('python/sensor/new_sensor'), params=payload)
    pp.pprint(r.json()['directives'])
    return r.json()['directives']

def unneeded_sensor(id):
    payload = {
        'section_id': id
    }
    r = requests.get(pico_uri('python/sensor/unneeded_sensor'), params=payload)
    pp.pprint(r.json())
    return r.json()['directives']

def new_temperature_reading(temp, eci):
    payload = {
        'genericThing': '{"data": {"temperature": {"temperatureF": ' + str(temp) + '}}}'
    }
    r = requests.get(pico_uri('python/wovyn/heartbeat', eci=eci), params=payload)
    pp.pprint(r.json())
    return r.json()['directives']

def profile_info(eci):
    r = requests.get(pico_uri('python/sensor/profile_info', eci=eci))
    pp.pprint(r.json())
    return r.json()['directives']

eci = new_sensor('temperature')[0]['options']['pico']['eci']
new_sensor('light')
new_sensor('distance')
unneeded_sensor('light')
unneeded_sensor('distance')
new_temperature_reading(74.6, eci)
new_temperature_reading(76.7, eci)
profile_info(eci)
view_test_data()
