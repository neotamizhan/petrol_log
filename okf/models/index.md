# Concepts

* [FillRecord](fill-record.md) - Immutable value object representing a single fuel fill event for a vehicle, with computed mileage and distance helpers.
* [FuelType](fuel-type.md) - Immutable fuel type carrying a per-litre price and its own display currency, referenced by fuel fill records.
* [MaintenanceRecord](maintenance-record.md) - Immutable service/maintenance event with optional next-due targets, grouped into schedules per vehicle and service type.
* [Vehicle](vehicle.md) - Immutable vehicle entity that owns fuel and maintenance records, with an odometer kept current by the provider.
